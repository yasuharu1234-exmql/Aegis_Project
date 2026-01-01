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
   
   //-------------------------------------------------------------------
   //| メイン更新処理（毎Tick呼び出し）                                   |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // Tick開始時にMODIFYフラグをリセット
      m_modify_done = false;
      
      // ========== 状態に応じた処理分岐 ==========
      switch(m_state)
      {
         case OCO_STATE_IDLE:
            return HandleIdle(data, tick_id);
            
         case OCO_STATE_ACTIVE:
            return HandleActive(data, tick_id);
            
         case OCO_STATE_COMPLETED:
            return HandleCompleted(data, tick_id);
            
         default:
            Print("❌ [OCO戦略] 未知の状態: ", m_state);
            return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 戦略完了状態を取得（Sprint E追加）                                  |
   //-------------------------------------------------------------------
   virtual bool IsCompleted() const override
   {
      return (m_state == OCO_STATE_COMPLETED);
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
      
      // 状態遷移
      m_state = OCO_STATE_ACTIVE;
      
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
         Print("✅ [OCO戦略] 片側約定を検出 → 反対側キャンセル要求");
         data.SetExecRequest(EXEC_REQ_CANCEL, tick_id);
         m_state = OCO_STATE_COMPLETED;
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
      if(!CheckSpread())
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
   bool CheckSpread()
   {
      double ask   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double bid   = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      if(ask <= 0 || bid <= 0 || point <= 0)
         return false;
      
      // スプレッド計算（ポイント）
      int spread_points = (int)((ask - bid) / point);
      
      // 最大許容スプレッドを超えている場合
      if(spread_points > m_max_spread_points)
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
      
      // BuyStop：価格を下げられるなら有利
      if(buy_ticket > 0)
      {
         double current_buy = data.GetOCOBuyPrice();
         double price_diff = (current_buy - new_buy) / point;
         
         if(price_diff >= m_trail_trigger_points)
         {
            data.SetOCOBuyPrice(new_buy);
            need_modify = true;
         }
      }
      
      // SellStop：価格を上げられるなら有利
      if(sell_ticket > 0)
      {
         double current_sell = data.GetOCOSellPrice();
         double price_diff = (new_sell - current_sell) / point;
         
         if(price_diff >= m_trail_trigger_points)
         {
            data.SetOCOSellPrice(new_sell);
            need_modify = true;
         }
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
   bool HandleCompleted(CLA_Data &data, ulong tick_id)
   {
      // ========== NOOP ==========
      // 何もしない（別Strategyにバトンタッチ）
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
