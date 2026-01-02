//+------------------------------------------------------------------+
//| File    : CStrategy_OCOFollow.mqh                                |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Decision / Strategy                                    |
//|                                                                  |
//| Role                                                             |
//|  - OCO（BuyStop/SellStop）を配置・管理する戦略                   |
//|  - 片側約定を検出し、反対側注文をキャンセルする                  |
//|  - 約定後のSL/TP追従は行わない（別Strategyへ委譲）               |
//|                                                                  |
//| Responsibility                                                   |
//|  - 判断のみ（OrderSendは絶対に使わない）                         |
//|  - CLA_Dataに対してSetExecRequest()で要求を出すのみ              |
//|  - 約定検出はPositionsTotal/OrdersTotalで状態確認のみ             |
//|                                                                  |
//| Design Policy (Sprint B)                                         |
//|  - OCO配置 → 片側約定検出 → 反対側キャンセル → 役割終了         |
//|  - 追従(MODIFY)は仮条件（毎Tick、現在価格±distance）             |
//|  - MODIFY は毎Tick1回まで                                        |
//|  - 約定検出後は即CANCEL → その後はNOOP                           |
//|                                                                  |
//| Phase 2-1 (Phase 6 状態ログ基盤整備)                              |
//|  - ログ状態管理用メンバ変数追加                                  |
//|  - m_stateのprivate化とアクセサ整備                              |
//|  - IDLE遷移時の自動ログリセット機構                              |
//|                                                                  |
//| Prohibited                                                       |
//|  - Execution層のロジック変更                                     |
//|  - ログ追加（CLA_Dataに任せる）                                  |
//|  - Gatekeeper判断                                                |
//|  - SL/TP追従                                                     |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "../03_Decision/CDecisionBase.mqh"

//+------------------------------------------------------------------+
//| OCO追従戦略クラス                                                 |
//+------------------------------------------------------------------+
class CStrategy_OCOFollow : public CDecisionBase
{
private:
   //--- 内部状態
   enum ENUM_OCO_STATE
   {
      OCO_STATE_IDLE = 0,      // 未配置
      OCO_STATE_ACTIVE,        // OCO配置済み・追従中
      OCO_STATE_COMPLETED      // 役割完了（片側約定→反対側キャンセル済み）
   };
   
   // ===== Phase 2-1: m_stateのprivate化 =====
   ENUM_OCO_STATE m_state;           // 現在の状態
   
   bool           m_modify_done;     // 今Tickで既にMODIFY済みか
   
   //--- 内部変数（input変数からコピー）
   int    m_oco_distance_points;      // OCO配置距離（ポイント）
   double m_oco_lot_size;             // ロットサイズ
   int    m_oco_sl_points;            // SL（ポイント）
   int    m_oco_tp_points;            // TP（ポイント）
   int    m_trail_trigger_points;     // 追従開始トリガー（ポイント）
   int    m_trail_interval_sec;       // 追従判定間隔（秒）
   int    m_max_spread_points;        // 最大許容スプレッド（ポイント）
   int    m_spread_wide_interval_sec; // スプレッド拡大時の待機時間（秒）
   bool   m_use_interval_ohlc;        // 間隔モード時にOHLCを使用
   int    m_max_trail_count;          // 最大追従回数（0=無制限）
   int    m_magic;                    // マジックナンバー
   
   //--- 内部状態変数
   datetime m_last_order_action_time; // 前回注文配置または変更成功時刻
   int      m_trail_count;            // 現在の追従回数
   
   // ===== Phase 2-1: ログ状態管理用メンバ変数 =====
   bool     m_no_change_logged;       // NO_CHANGE初回ログ済みフラグ
   bool     m_spread_ng_prev;         // 前回スプレッド状態（NG=true）
   int      m_spread_last_logged;     // 前回ログ記録時のスプレッド値（pt）
   double   m_buy_price_last_logged;  // 前回ログ記録時のBuy価格
   double   m_sell_price_last_logged; // 前回ログ記録時のSell価格
   
   //+------------------------------------------------------------------+
   //| ログ状態リセット（Phase 2-1 追加）                                    |
   //+------------------------------------------------------------------+
   void ResetLogState()
   {
      m_no_change_logged = false;
      m_spread_ng_prev = false;
      m_spread_last_logged = 0;
      m_buy_price_last_logged = 0.0;
      m_sell_price_last_logged = 0.0;
   }

public:
   //-------------------------------------------------------------------
   //| コンストラクタ（Phase 2: デフォルト値のみ）                        |
   //-------------------------------------------------------------------
   CStrategy_OCOFollow()
      : CDecisionBase(FUNC_ID_DECISION_EVALUATOR, 100)
   {
      m_state = OCO_STATE_IDLE;
      m_modify_done = false;
      
      // 内部変数の初期化（デフォルト値）
      m_oco_distance_points = 0;
      m_oco_lot_size = 0.0;
      m_oco_sl_points = 0;
      m_oco_tp_points = 0;
      m_trail_trigger_points = 0;
      m_trail_interval_sec = 0;
      m_max_spread_points = 0;
      m_spread_wide_interval_sec = 0;
      m_use_interval_ohlc = false;
      m_max_trail_count = 0;
      m_magic = 0;
      
      // 内部状態の初期化
      m_last_order_action_time = 0;
      m_trail_count = 0;
      
      // Phase 2-1 追加: ログ状態初期化
      m_no_change_logged = false;
      m_spread_ng_prev = false;
      m_spread_last_logged = 0;
      m_buy_price_last_logged = 0.0;
      m_sell_price_last_logged = 0.0;
   }
   
   //-------------------------------------------------------------------
   //| 初期化（Phase 2: inputから内部変数へコピー）                        |
   //-------------------------------------------------------------------
   virtual bool Init(
      int oco_distance,
      double oco_lot,
      int oco_sl,
      int oco_tp,
      int trail_trigger,
      int trail_interval,
      int max_spread,
      int spread_wide_interval,
      bool use_interval_ohlc,
      int max_trail_count,
      int magic
   ) 
   {
      // inputから内部変数へコピー
      m_oco_distance_points       = oco_distance;
      m_oco_lot_size              = oco_lot;
      m_oco_sl_points             = oco_sl;
      m_oco_tp_points             = oco_tp;
      m_trail_trigger_points      = trail_trigger;
      m_trail_interval_sec        = trail_interval;
      m_max_spread_points         = max_spread;
      m_spread_wide_interval_sec  = spread_wide_interval;
      m_use_interval_ohlc         = use_interval_ohlc;
      m_max_trail_count           = max_trail_count;
      m_magic                     = magic;
      
      // 内部状態初期化
      m_last_order_action_time = 0;
      m_trail_count = 0;
      
      m_initialized = true;
      
      Print("[OCO戦略] 初期化完了: 距離=", m_oco_distance_points, "pt, ロット=", m_oco_lot_size,
            ", 追従トリガー=", m_trail_trigger_points, "pt, 最大追従回数=", 
            (m_max_trail_count == 0 ? "無制限" : IntegerToString(m_max_trail_count)));
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 旧Init()（互換性のため残す - 非推奨）                              |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      Print("[警告] Init()はパラメータ付きのInit()を使用してください");
      return false;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理                                                           |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[OCO戦略] 終了処理");
   }
   
   //+------------------------------------------------------------------+
   //| 状態遷移（Phase 2-1 追加）                                          |
   //+------------------------------------------------------------------+
   void EnterState(ENUM_OCO_STATE new_state)
   {
      m_state = new_state;
      
      // IDLE遷移時にログ状態リセット
      if(new_state == OCO_STATE_IDLE)
      {
         ResetLogState();
      }
   }
   
   //+------------------------------------------------------------------+
   //| 状態取得（Phase 2-1 追加）                                          |
   //+------------------------------------------------------------------+
   ENUM_OCO_STATE GetState() const { return m_state; }
   
   //-------------------------------------------------------------------
   //| メイン更新処理（毎Tick呼び出し）                                   |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // Tick開始時にMODIFYフラグをリセット
      m_modify_done = false;
      
      // ========== 状態に応じた処理分岐 ==========
      // Phase 2-1: GetState()経由に変更
      switch(GetState())
      {
         case OCO_STATE_IDLE:
            return HandleIdle(data, tick_id);
            
         case OCO_STATE_ACTIVE:
            return HandleActive(data, tick_id);
            
         case OCO_STATE_COMPLETED:
            return HandleCompleted(data, tick_id);
            
         default:
            Print("❌ [OCO戦略] 未知の状態: ", GetState());
            return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 戦略完了状態を取得（Sprint E追加）                                  |
   //-------------------------------------------------------------------
   virtual bool IsCompleted() const override
   {
      // Phase 2-1: GetState()経由に変更
      return (GetState() == OCO_STATE_COMPLETED);
   }

private:
   //-------------------------------------------------------------------
   //| 状態: IDLE（OCO未配置）                                            |
   //-------------------------------------------------------------------
   bool HandleIdle(CLA_Data &data, ulong tick_id)
   {
      // ========== 配置条件チェック ==========
      // 1. ポジションが存在しないこと
      if(PositionsTotal() > 0)
      {
         return true; // 何もしない（他戦略のポジションがある）
      }
      
      // 2. OCO注文が存在しないこと
      if(CountOCOOrders(data) > 0)
      {
         return true; // 既に注文がある（異常状態だが安全のため何もしない）
      }
      
      // ========== OCO配置要求 ==========
      // パラメータをCLA_Dataに設定
      data.SetOCOLot(m_oco_lot_size);
      data.SetOCODistancePoints(m_oco_distance_points);
      data.SetOCOSLPoints(m_oco_sl_points);
      data.SetOCOTPPoints(m_oco_tp_points);
      data.SetOCOMagic(m_magic);
      
      // Execution層に配置要求
      data.SetExecRequest(EXEC_REQ_PLACE, tick_id);
      
      // Phase 2-1: EnterState()経由に変更
      EnterState(OCO_STATE_ACTIVE);
      
      // Phase 2-2: OCO配置ログ（配置成功は次Tickで確認されるため、ここでは配置要求のみ記録）
      if(InpEnableStateLog)
      {
         double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
         double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
         int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
         
         double buy_price = NormalizeDouble(ask + m_oco_distance_points * point, digits);
         double sell_price = NormalizeDouble(bid - m_oco_distance_points * point, digits);
         
         data.AddLogEx(
            LOG_ID_OCO_PLACE,
            "OCO_PLACE",
            "0",  // チケット番号は次Tickで確定
            DoubleToString(buy_price, digits),
            "0",  // チケット番号は次Tickで確定
            DoubleToString(sell_price, digits),
            StringFormat("距離=%dpt", m_oco_distance_points),
            false
         );
      }
      
      Print("✅ [OCO戦略] OCO配置要求: 距離=", m_oco_distance_points, "pt");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 状態: ACTIVE（OCO配置済み・追従中）                                |
   //-------------------------------------------------------------------
   //-------------------------------------------------------------------
   //| 状態: ACTIVE（OCO配置済み・追従中）Phase 4強化版                   |
   //-------------------------------------------------------------------
   bool HandleActive(CLA_Data &data, ulong tick_id)
   {
      // ========== 約定検出 ==========
      if(PositionsTotal() > 0)
      {
         // Phase 2-2: 約定検出ログ
         if(InpEnableStateLog)
         {
            data.AddLogEx(
               LOG_ID_FILL_DETECT,
               "FILL_DETECT",
               "",
               "",
               "",
               "",
               "片側約定検出",
               false
            );
         }
         
         Print("✅ [OCO戦略] 片側約定を検出 → 反対側キャンセル要求");
         data.SetExecRequest(EXEC_REQ_CANCEL, tick_id);
         // Phase 2-1: EnterState()経由に変更
         EnterState(OCO_STATE_COMPLETED);
         return true;
      }
      
      // ========== 追従（MODIFY）判定 ==========
      
      // 1. 同一Tick 1回まで
      if(m_modify_done)
         return true;
      
      // 2. 追従間隔チェック
      if(!CheckTrailInterval(data))
         return true;
      
      // 3. スプレッドチェック
      if(!CheckSpread(data))
         return true;
      
      // 4. 最大追従回数チェック
      if(!CheckMaxTrailCount())
         return true;
      
      // 5. 追従トリガー判定
      if(!CheckTrailTrigger(data))
         return true;
      
      // 6. MODIFY要請
      RequestModify(data, tick_id);
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 追従間隔チェック                                                   |
   //-------------------------------------------------------------------
   bool CheckTrailInterval(CLA_Data &data)
   {
      // InpTrailIntervalSec = 0 の場合は毎Tick実行
      if(m_trail_interval_sec == 0)
         return true;
      
      // 前回MODIFY成功時刻から指定秒数経過しているかチェック
      datetime current_time = TimeCurrent();
      datetime last_time = data.GetLastOrderActionTime();
      
      if(last_time == 0)
         return true; // 初回
      
      int elapsed_sec = (int)(current_time - last_time);
      
      if(elapsed_sec < m_trail_interval_sec)
      {
         // まだ間隔が経過していない
         return false;
      }
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| スプレッドチェック                                                 |
   //-------------------------------------------------------------------
   bool CheckSpread(CLA_Data &data)
   {
      double ask   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double bid   = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      if(ask <= 0 || bid <= 0 || point <= 0)
         return false;
      
      // スプレッド計算（ポイント）
      int spread_points = (int)((ask - bid) / point);
      bool spread_ok = (spread_points <= m_max_spread_points);
      
      // Phase 2-2: スプレッド状態ログ（状態遷移時のみ）
      if(InpEnableStateLog && spread_ok != m_spread_ng_prev)
      {
         int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
         
         if(spread_ok)
         {
            // OK状態に遷移
            data.AddLogEx(
               LOG_ID_SPREAD_OK,
               "SPREAD_OK",
               IntegerToString(spread_points),
               IntegerToString(m_max_spread_points),
               DoubleToString(ask, digits),
               DoubleToString(bid, digits),
               "スプレッド正常化",
               false
            );
         }
         else
         {
            // NG状態に遷移
            data.AddLogEx(
               LOG_ID_SPREAD_SKIP,
               "SPREAD_SKIP",
               IntegerToString(spread_points),
               IntegerToString(m_max_spread_points),
               DoubleToString(ask, digits),
               DoubleToString(bid, digits),
               "スプレッド超過で追従中断",
               false
            );
         }
         
         m_spread_ng_prev = !spread_ok;
         m_spread_last_logged = spread_points;
      }
      
      // 最大許容スプレッドを超えている場合
      if(!spread_ok)
      {
         Print("[OCO戦略] スプレッド拡大: ", spread_points, "pt > ", m_max_spread_points, "pt → 追従スキップ");
         return false;
      }
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 最大追従回数チェック                                               |
   //-------------------------------------------------------------------
   bool CheckMaxTrailCount()
   {
      // InpMaxTrailCount = 0 の場合は無制限
      if(m_max_trail_count == 0)
         return true;
      
      // 最大追従回数に達している場合
      if(m_trail_count >= m_max_trail_count)
      {
         Print("[OCO戦略] 最大追従回数到達: ", m_trail_count, " / ", m_max_trail_count, " → 追従停止");
         return false;
      }
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 追従トリガー判定                                                   |
   //-------------------------------------------------------------------
   bool CheckTrailTrigger(CLA_Data &data)
   {
      // OCOチケット確認
      ulong buy_ticket  = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      if(buy_ticket == 0 && sell_ticket == 0)
         return false; // 注文が存在しない
      
      // 現在価格取得
      double ask   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double bid   = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      if(ask <= 0 || bid <= 0 || point <= 0)
         return false; // 価格取得失敗
      
      // ========== 追従トリガー判定（Phase 4: 簡易版 - 現在価格のみ） ==========
      // Phase 4ではOHLC比較は簡易実装とし、現在価格のみで判定
      // 将来拡張: InpUseIntervalOHLC=trueの場合、CopyRates()でOHLCを取得
      
      int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      double new_buy  = NormalizeDouble(ask + m_oco_distance_points * point, digits);
      double new_sell = NormalizeDouble(bid - m_oco_distance_points * point, digits);
      
      bool need_modify = false;
      double buy_diff_pt = 0;
      double sell_diff_pt = 0;
      
      // BuyStop：価格を下げられるなら有利
      if(buy_ticket > 0)
      {
         double current_buy = data.GetOCOBuyPrice();
         buy_diff_pt = (current_buy - new_buy) / point;
         
         if(buy_diff_pt >= m_trail_trigger_points)
         {
            data.SetOCOBuyPrice(new_buy);
            need_modify = true;
         }
      }
      
      // SellStop：価格を上げられるなら有利
      if(sell_ticket > 0)
      {
         double current_sell = data.GetOCOSellPrice();
         sell_diff_pt = (new_sell - current_sell) / point;
         
         if(sell_diff_pt >= m_trail_trigger_points)
         {
            data.SetOCOSellPrice(new_sell);
            need_modify = true;
         }
      }
      
      // Phase 2-2: ログ追加
      if(InpEnableStateLog)
      {
         double max_diff = MathMax(buy_diff_pt, sell_diff_pt);
         
         // NO_CHANGE判定（両方がInpNoChangeLogDelta未満）
         if(buy_diff_pt < InpNoChangeLogDelta && sell_diff_pt < InpNoChangeLogDelta)
         {
            if(!m_no_change_logged)
            {
               data.AddLogEx(
                  LOG_ID_NO_CHANGE,
                  "NO_CHANGE",
                  DoubleToString(buy_diff_pt, 1),
                  DoubleToString(sell_diff_pt, 1),
                  IntegerToString(InpNoChangeLogDelta),
                  "",
                  "価格変更不要",
                  false
               );
               m_no_change_logged = true;
            }
         }
         // 追従トリガー発動
         else if(need_modify)
         {
            data.AddLogEx(
               LOG_ID_TRAIL_TRIGGER,
               "TRAIL_TRIGGER",
               DoubleToString(max_diff, 1),
               IntegerToString(m_trail_trigger_points),
               IntegerToString(m_trail_count),
               IntegerToString(m_max_trail_count),
               "追従トリガー発動",
               false
            );
            
            // 追従実行時はNO_CHANGEフラグをリセット
            m_no_change_logged = false;
         }
         // 中間値（InpNoChangeLogDelta 〜 InpTrailTriggerPoints）→ ログなし
      }
      
      return need_modify;
   }
   
   //-------------------------------------------------------------------
   //| MODIFY要請                                                         |
   //-------------------------------------------------------------------
   void RequestModify(CLA_Data &data, ulong tick_id)
   {
      data.SetExecRequest(EXEC_REQ_MODIFY, tick_id);
      m_modify_done = true;
      m_trail_count++; // 追従回数をインクリメント
      
      double new_buy  = data.GetOCOBuyPrice();
      double new_sell = data.GetOCOSellPrice();
      
      string count_str = (m_max_trail_count == 0) ? "無制限" : IntegerToString(m_max_trail_count);
      Print("✅ [OCO戦略] 追従更新要求: Buy=", new_buy, " Sell=", new_sell, 
            " (", m_trail_count, "/", count_str, ")");
   }
   
   //-------------------------------------------------------------------
   //| 状態: COMPLETED（役割完了）                                        |
   //-------------------------------------------------------------------
   //-------------------------------------------------------------------
   //| 状態: COMPLETED（役割完了）Phase 5: IDLE遷移実装                   |
   //-------------------------------------------------------------------
   bool HandleCompleted(CLA_Data &data, ulong tick_id)
   {
      // ========== ポジションクローズ検出 → IDLE遷移 ==========
      if(PositionsTotal() == 0)
      {
         // Phase 2-1: EnterState()経由に変更（自動でResetLogState()が呼ばれる）
         EnterState(OCO_STATE_IDLE);
         m_trail_count = 0; // 追従回数をリセット
         Print("✅ [OCO戦略] ポジションクローズ検出 → IDLE状態へ遷移");
      }
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| OCO注文数をカウント                                                |
   //-------------------------------------------------------------------
   int CountOCOOrders(CLA_Data &data)
   {
      int count = 0;
      ulong buy_ticket = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      
      // BuyStopの存在確認
      if(buy_ticket > 0)
      {
         if(OrderSelect(buy_ticket))
         {
            count++;
         }
      }
      
      // SellStopの存在確認
      if(sell_ticket > 0)
      {
         if(OrderSelect(sell_ticket))
         {
            count++;
         }
      }
      
      return count;
   }
};
