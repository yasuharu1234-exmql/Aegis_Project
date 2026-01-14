//+------------------------------------------------------------------+
//| File    : CObservationMarketScan.mqh                             |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Observation（Research Mode）                          |
//|                                                                  |
//| Phase D-1: Market Scan                                           |
//| 「一方的で激しい価格変動区間」を計測・抽出する                      |
//|                                                                  |
//| Purpose                                                          |
//|  - 1000Tick ウィンドウで mfe/mae を計測                            |
//|  - trend_score = mfe - mae を算出                                |
//|  - 上位5スコアを保持（移動ランキング）                             |
//|  - 上位5を超えたら ログ出力＋ランキング更新                         |
//|                                                                  |
//| Design Notes                                                     |
//|  - 売買・判断・裁定は一切しない（計測のみ）                        |
//|  - 既存EAパイプラインに干渉しない                                 |
//|  - window は常に1000Tick固定（ログ出力後もリセットしない）          |
//|  - BasePrice は window開始時点で固定                              |
//|                                                                  |
//+------------------------------------------------------------------+

#ifndef __CObservationMarketScan_mqh__
#define __CObservationMarketScan_mqh__

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CObservationBase.mqh"

// ========== Phase D-1: 定数定義（#define使用） ==========
#define MARKET_SCAN_TICK_WINDOW   1000    // 計測ウィンドウ（Tick）
#define MARKET_SCAN_TOP_RANK      5       // 上位ランキング件数

//+------------------------------------------------------------------+
//| Class   : CObservationMarketScan                                 |
//| Layer   : Observation（Research）                               |
//| Purpose : 市場の激しい変動区間を計測・抽出                         |
//+------------------------------------------------------------------+
class CObservationMarketScan : public CObservationBase
{
private:

   // ========== ウィンドウ管理 ==========
   int m_tick_count;           // 現在のウィンドウ内Tick数
   double m_base_price;        // window開始時の価格（固定）
   double m_max_price;         // window内の最高値
   double m_min_price;         // window内の最安値

   // ========== スコア管理 ==========
   double m_top_scores[5];     // 上位5スコア（移動ランキング）★固定サイズ5
   int m_top_count;            // 現在のランキング登録数（0～5）

   // ========== 計測値 ==========
   double m_mfe;               // Maximum Favorable Excursion
   double m_mae;               // Maximum Adverse Excursion
   double m_trend_score;       // trend_score = mfe - mae

   //-------------------------------------------------------------------
   //| ヘルパー: スコアを上位5に追加（ソート付き）                       |
   //-------------------------------------------------------------------
   void AddScoreToRanking(double score)
   {
      // 既にランキングに同じスコアがあれば無視
      for(int i = 0; i < m_top_count; i++)
      {
         if(MathAbs(m_top_scores[i] - score) < 0.0001)
         {
            // 既存 → ソート後のランキング位置に移動
            return;
         }
      }

      // ランキングに追加
      if(m_top_count < MARKET_SCAN_TOP_RANK)
      {
         // スロットが空いている → 追加
         m_top_scores[m_top_count] = score;
         m_top_count++;
      }
      else
      {
         // スロットが満杯 → 最小値を置き換え
         int min_idx = 0;
         double min_val = m_top_scores[0];
         for(int i = 1; i < MARKET_SCAN_TOP_RANK; i++)
         {
            if(m_top_scores[i] < min_val)
            {
               min_val = m_top_scores[i];
               min_idx = i;
            }
         }
         m_top_scores[min_idx] = score;
      }

      // ソート（昇順）
      for(int i = 0; i < m_top_count - 1; i++)
      {
         for(int j = i + 1; j < m_top_count; j++)
         {
            if(m_top_scores[i] > m_top_scores[j])
            {
               double tmp = m_top_scores[i];
               m_top_scores[i] = m_top_scores[j];
               m_top_scores[j] = tmp;
            }
         }
      }
   }

   //-------------------------------------------------------------------
   //| ヘルパー: 上位5の最小値を取得                                    |
   //-------------------------------------------------------------------
   double GetMinTopScore() const
   {
      if(m_top_count == 0) return -DBL_MAX;  // ランキング空 → すべて採用
      return m_top_scores[0];                 // 昇順ソート済み → [0]が最小
   }

   //-------------------------------------------------------------------
   //| ヘルパー: window をリセット                                      |
   //-------------------------------------------------------------------
   void ResetWindow()
   {
      m_tick_count = 0;
      double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      m_base_price = current_bid;
      m_max_price = current_bid;
      m_min_price = current_bid;
   }

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                   |
   //| ★修正: CObservationBase(ENUM_FUNCTION_ID) の形式に統一           |
   //-------------------------------------------------------------------
   CObservationMarketScan()
      : CObservationBase(FUNC_ID_OBS_MARKET_SCAN)
   {
      m_tick_count = 0;
      m_base_price = 0.0;
      m_max_price = 0.0;
      m_min_price = 0.0;
      m_top_count = 0;
      m_mfe = 0.0;
      m_mae = 0.0;
      m_trend_score = 0.0;

      for(int i = 0; i < MARKET_SCAN_TOP_RANK; i++)
      {
         m_top_scores[i] = 0.0;
      }
   }

   //-------------------------------------------------------------------
   //| デストラクタ                                                     |
   //-------------------------------------------------------------------
   virtual ~CObservationMarketScan()
   {
   }

   //-------------------------------------------------------------------
   //| 初期化メソッド                                                   |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CObservationBase::Init())
      {
         Print("[MarketScan] 親クラス初期化失敗");
         return false;
      }

      // 初期状態でウィンドウをリセット
      ResetWindow();

      Print("[MarketScan] 初期化成功 (TICK_WINDOW=", MARKET_SCAN_TICK_WINDOW, " TOP_RANK=", MARKET_SCAN_TOP_RANK, ")");
      return true;
   }

   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                 |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[MarketScan] 終了処理");
      
      // ★Phase D-1: 上位5ランキングをコンソール出力（デバッグ用）
      Print("[MarketScan] 最終ランキング（上位5）:");
      for(int i = 0; i < m_top_count; i++)
      {
         Print("[MarketScan]   Rank#", (i+1), ": TrendScore=", StringFormat("%.2f", m_top_scores[i]));
      }
      
      CObservationBase::Deinit();
   }

   //-------------------------------------------------------------------
   //| 更新メソッド（毎Tick呼び出し）                                   |
   //|                                                                  |
   //| [処理フロー]                                                     |
   //| 1. 現在価格を取得                                                |
   //| 2. max/min を更新                                                |
   //| 3. mfe/mae を計算                                                |
   //| 4. tick_count をインクリメント                                    |
   //| 5. tick_count == 1000 に達したら：                               |
   //|    - trend_score = mfe - mae を計算                              |
   //|    - score が top_scores の最小値を超えたらログ出力＋更新         |
   //|    - ウィンドウをリセット                                        |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // 現在価格取得
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      if(bid <= 0.0 || point <= 0.0)
      {
         return false;
      }

      // ========== ステップ1-3: max/min更新 & mfe/mae計算 ==========
      if(m_tick_count == 0)
      {
         // window開始時（初回 or リセット直後）
         m_base_price = bid;
         m_max_price = bid;
         m_min_price = bid;
      }
      else
      {
         // window進行中
         if(bid > m_max_price) m_max_price = bid;
         if(bid < m_min_price) m_min_price = bid;
      }

      // mfe/mae 計算
      m_mfe = m_max_price - m_base_price;
      m_mae = m_base_price - m_min_price;

      // ========== ステップ4: tick_count インクリメント ==========
      m_tick_count++;

      // ========== ステップ5: window満了判定 ==========
      if(m_tick_count >= MARKET_SCAN_TICK_WINDOW)
      {
         m_trend_score = m_mfe - m_mae;

         // score が top_scores の最小値を超えたか判定
         double min_top = GetMinTopScore();
         if(m_trend_score > min_top)
         {
            // ✅ ログ出力
            int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

            data.AddLogEx(
               LOG_ID_MARKET_SCAN,
               "MarketScan Event",
               StringFormat("%.5f", m_base_price),
               StringFormat("%.5f", m_max_price),
               StringFormat("%.5f", m_min_price),
               StringFormat("%.2f", m_trend_score),
               StringFormat(
                  "BasePrice=%.5f MaxPrice=%.5f MinPrice=%.5f MFE=%.5f MAE=%.5f TrendScore=%.2f TickCount=%d",
                  m_base_price, m_max_price, m_min_price, m_mfe, m_mae, m_trend_score, MARKET_SCAN_TICK_WINDOW),
               false  // important
            );

            // ✅ ランキング更新
            AddScoreToRanking(m_trend_score);
         }

         // ✅ ウィンドウをリセット（常に1000Tick固定）
         ResetWindow();
      }

      return true;
   }

   //-------------------------------------------------------------------
   //| ゲッター: 現在の trend_score を取得                               |
   //-------------------------------------------------------------------
   double GetTrendScore() const
   {
      return m_trend_score;
   }

   //-------------------------------------------------------------------
   //| ゲッター: 現在の window 進捗（%）を取得                           |
   //-------------------------------------------------------------------
   int GetWindowProgress() const
   {
      if(m_tick_count == 0) return 0;
      return (m_tick_count * 100) / MARKET_SCAN_TICK_WINDOW;
   }

   //-------------------------------------------------------------------
   //| ゲッター: 上位ランキング（デバッグ用）                            |
   //-------------------------------------------------------------------
   void GetTopRanking(double &scores[], int &count) const
   {
      count = m_top_count;
      for(int i = 0; i < m_top_count && i < MARKET_SCAN_TOP_RANK; i++)
      {
         scores[i] = m_top_scores[i];
      }
   }
};

#endif  // __CObservationMarketScan_mqh__
