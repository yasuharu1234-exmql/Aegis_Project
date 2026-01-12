//+------------------------------------------------------------------+
//| File    : CDecisionOCOFollow.mqh                                 |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Decision                                               |
//|                                                                  |
//| フェーズB実装                                                      |
//| 追従型OCO戦略用の判断層                                            |
//|                                                                  |
//| Role                                                             |
//|  - 観測層から「エントリー可能か否か」の事実を取得する                |
//|  - フェーズBでは受信確認のみ（Action決定はフェーズC以降）            |
//|                                                                  |
//| Design Policy                                                    |
//|  - CLA_Data経由でのみ観測結果を取得（観測層への直接参照なし）        |
//|  - フェーズBでは判断ロジックを実装しない                            |
//|  - Decision ArbiterはフェーズC以降                                |
//|                                                                  |
//| Future (フェーズC以降)                                             |
//|  - エントリー可否の最終判断                                         |
//|  - 追従型OCOのAction生成                                           |
//|  - Decision Arbiterとの連携                                       |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CDecisionBase.mqh"

// ========== Phase C-7.2: 挟み撃ちトレイル定数 ==========
#define SANDWICH_K                2.0    // 係数K
#define SANDWICH_MIN_SL_POINTS   50.0    // SL最低距離(points)
#define SANDWICH_MIN_TP_POINTS   50.0    // TP最低距離(points)


//+------------------------------------------------------------------+
//| Class   : CDecisionOCOFollow                                     |
//| Layer   : Decision                                               |
//| Purpose : 追従型OCO戦略の判断層（フェーズB: 最小実装）              |
//+------------------------------------------------------------------+
class CDecisionOCOFollow : public CDecisionBase
{
private:
   
   bool m_last_entry_clear;  // 最後に取得したエントリー可能状態

   //-------------------------------------------------------------------
   //| BE（ブレイクイーブン）判定（Phase C-7.1b）                        |
   //| [戻り値]                                                          |
   //|   true  : BE条件達成（含み益がトリガー以上）                       |
   //|   false : BE未達                                                  |
   //-------------------------------------------------------------------
   bool IsBreakEvenReached()
   {
      // ポジション情報取得
      if(PositionsTotal() == 0) return false;
      
      ulong ticket = PositionGetTicket(0);
      if(ticket == 0) return false;
      
      double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      // 現在価格取得
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double current_price = (pos_type == POSITION_TYPE_BUY) ? bid : ask;
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      
      // 含み益計算（points）
      double profit_points = 0.0;
      if(pos_type == POSITION_TYPE_BUY)
      {
         profit_points = (current_price - open_price) / point;
      }
      else
      {
         profit_points = (open_price - current_price) / point;
      }
      
      // BEトリガー：10pips = 100points（仮）
      double be_trigger_points = 100.0;
      
      return (profit_points >= be_trigger_points);
   }
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //| [引数]                                                            |
   //|   priority : 優先度（デフォルト100）                                |
   //-------------------------------------------------------------------
   CDecisionOCOFollow(int priority = 100)
      : CDecisionBase(FUNC_ID_LOGIC_RSI_SIMPLE, priority)
   {
      m_last_entry_clear = false;
   }

   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CDecisionBase::Init())
      {
         Print("[OCOFollow判断] 初期化失敗");
         return false;
      }

      m_last_entry_clear = false;

      Print("[OCOFollow判断] 初期化成功（フェーズB: 観測データ受信確認のみ）");
      return true;
   }

   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[OCOFollow判断] 終了処理");
      CDecisionBase::Deinit();
   }

   //-------------------------------------------------------------------
   //| 更新メソッド（フェーズB実装: 受信確認のみ）                         |
   //| [引数]                                                            |
   //|   data    : システム共通データ（参照渡し）                            |
   //|   tick_id : この操作のユニークID                                    |
   //| [戻り値]                                                          |
   //|   true  : 更新成功                                                |
   //|   false : 更新失敗                                                |
   //|                                                                  |
   //| [フェーズB実装内容]                                                |
   //|   - CLA_Dataから観測結果を取得                                     |
   //|   - 受信できることを確認するだけ                                    |
   //|   - Signal生成・Action決定は行わない                               |
   //|                                                                  |
   //| [フェーズC以降の実装予定]                                           |
   //|   - エントリー可否の最終判断                                        |
   //|   - 追従型OCOのAction生成                                          |
   //|   - Decision Arbiterとの連携                                      |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // ★フェーズB: CLA_Dataから観測結果を取得
      bool entry_clear = data.GetObs_EntryClear();

      // 状態保存（フェーズBでは使用しない）
      m_last_entry_clear = entry_clear;

      // ★フェーズB: 受信確認のみ（ログ出力なし、Signal生成なし）
      // この時点では何もしない

      // フェーズC以降で実装予定:
      // - if(entry_clear) { ... Action生成 ... }
      // - Decision Arbiterへの登録
      // - ログ出力

      return true;
   }


   //-------------------------------------------------------------------
   //| Action候補生成（フェーズF-2実装: オーバーライド）                   |
   //| [引数]                                                            |
   //|   data    : システム共通データ                                     |
   //|   tick_id : この操作のユニークID                                   |
   //| [戻り値]                                                          |
   //|   Action  : このStrategyが推奨するAction                          |
   //|                                                                  |
   //| [フェーズF-2実装内容]                                              |
   //|   - 仮実装: ACTION_NONE を返す                                    |
   //|   - 全フィールドは初期値（0/空）のまま                              |
   //|                                                                  |
   //| [フェーズF-3以降の実装予定]                                         |
   //|   - エントリー条件判定                                             |
   //|   - 価格計算                                                      |
   //|   - ロット計算                                                     |
   //|   - SL/TP設定                                                     |
   //|   - ACTION_OCO_PLACE / MODIFY / CANCEL の適切な選択               |
   //-------------------------------------------------------------------
   virtual Action GenerateActionCandidate(CLA_Data &data, ulong tick_id) override
   {
      Action action;  // コンストラクタで初期化済み（全て0/空）

      // ========== Phase C-2.5: NTick判断ゲート ==========

      // ========== Phase C-7.1c: BE優先判定 ==========
      // ポジション状態観測データを取得
      bool has_position = data.GetHasPosition();
      bool be_reached = data.GetBEReached();
      bool be_applied = data.GetBEAlreadyApplied();
      
      // BE条件達成かつ未適用の場合は、interval関係なく処理
      if(has_position && be_reached && !be_applied)
      {
         action.type = ACTION_BE_APPLY;
         action.reason = "BE trigger reached (priority)";
         Print("[Aegis-TRACE][Decision] return Action=ACTION_BE_APPLY (BE priority)");
         return action;
      }
      bool interval_completed = data.GetObs_IntervalCompleted();
      
      if(!interval_completed)
      {
         // インターバル未完了：判断をスキップ
         action.type = ACTION_NONE;
         action.reason = "Skip: Interval not completed";
         // Phase C-4.2: skipログは InpEnableTraceSpam 時のみ
         if(InpEnableTraceSpam)
         {
            Print("[Aegis-TRACE][Decision] skip (interval not completed)");
         }
         return action;
      }
      

      // ========== Phase C-7.2: 挟み撃ちトレイル判定 ==========
      // BE適用済み & interval完了 の場合のみ評価
      if(has_position && be_applied && interval_completed)
      {
         bool tracking_init = data.GetSandwichTrackingInit();
         if(tracking_init)
         {
            double min_price = data.GetSandwichMinPrice();
            double max_price = data.GetSandwichMaxPrice();
            double current_sl = data.GetSandwichCurrentSL();
            double current_tp = data.GetSandwichCurrentTP();
            double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
            
            // 次SL候補計算
            double next_sl = (min_price + current_sl) / SANDWICH_K;
            double sl_distance = (next_sl - min_price) / point;
            bool sl_adopted = (sl_distance >= SANDWICH_MIN_SL_POINTS);
            
            // 次TP候補計算（SL未採用の場合のみ）
            double next_tp = 0.0;
            double tp_distance = 0.0;
            bool tp_adopted = false;
            
            if(!sl_adopted)
            {
               next_tp = (current_tp + max_price) / SANDWICH_K;
               tp_distance = (next_tp - max_price) / point;
               tp_adopted = (tp_distance >= SANDWICH_MIN_TP_POINTS);
            }
            
            // Phase C-7.2a: 挟み撃ち評価ログ（1行）
            ulong ticket = (PositionsTotal() > 0) ? PositionGetTicket(0) : 0;
            double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            
            string sl_reason = sl_adopted ? "採用" : StringFormat("距離不足(%.1fpt)", sl_distance);
            string tp_reason = (!sl_adopted && tp_adopted) ? "採用" : 
                              (!sl_adopted) ? StringFormat("距離不足(%.1fpt)", tp_distance) : "未評価";
            string final_action = sl_adopted ? "SL更新" : (tp_adopted ? "TP更新" : "更新なし");
            
            data.AddLogEx(
               LOG_ID_SANDWICH_EVAL,
               "挟み撃ち評価",
               StringFormat("%.5f", current_price),
               StringFormat("%.5f", current_sl),
               StringFormat("%.5f", current_tp),
               StringFormat("%.5f", min_price),
               StringFormat("最大=%.5f 次SL=%.5f(%s) 次TP=%.5f(%s) → %s",
                           max_price, next_sl, sl_reason, next_tp, tp_reason, final_action),
               false  // important
            );
            
            // Action決定
            if(sl_adopted)
            {
               action.type = ACTION_SANDWICH_TRAIL;
               action.reason = "Sandwich trail: SL update";
               action.sl = next_sl;
               action.tp = current_tp;
               return action;
            }
            else if(tp_adopted)
            {
               action.type = ACTION_SANDWICH_TRAIL;
               action.reason = "Sandwich trail: TP update";
               action.sl = current_sl;
               action.tp = next_tp;
               return action;
            }
         }
      }
      
      // インターバル完了：判断を実行
      ulong interval_id = data.GetObs_IntervalID();
      double window_high = data.GetObs_WindowHigh();
      double window_low = data.GetObs_WindowLow();
      
      Print("[Aegis-TRACE][Decision] run interval_id=", interval_id,
            " high=", DoubleToString(window_high, 5),
            " low=", DoubleToString(window_low, 5));

      // ========== 共通: 価格情報取得 ==========
      double ask   = data.GetCurrentAsk();
      double bid   = data.GetCurrentBid();
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      int    digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);


      /*DEBUG*/
      Print("[Aegis-TRACE][Decision][FUNC_TOP]",
            " ask=", ask,
            " bid=", bid,
            " point=", point,
            " digits=", digits);
      /*DEBUG*/


      // ========== 状態確認 ==========
      ulong buy_ticket  = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      bool has_oco_orders = (buy_ticket > 0 || sell_ticket > 0);

      // ★★★ トレースログ: 関数開始 ★★★
      Print("[Aegis-TRACE][Decision] === GenerateActionCandidate START ===");
      Print("[Aegis-TRACE][Decision] buy_ticket=", buy_ticket, " sell_ticket=", sell_ticket);
      Print("[Aegis-TRACE][Decision] has_oco_orders=", has_oco_orders, " has_position=", has_position);

      // ========== 優先順位1: CLOSE（ポジション＋残存OCO注文） ==========
      // ★Phase C-5: 片側約定後、反対側を閉じる
      if(has_position && has_oco_orders)
      {
         action.type = ACTION_OCO_CLOSE;
         action.reason = "OCO_CLOSE: Position filled";
         Print("[Aegis-TRACE][Decision] return Action=ACTION_OCO_CLOSE");
         return action;
      }

      // ========== 優先順位2: BE判定（ポジションのみ、OCO無し） ==========
      // ★Phase C-7.1b: BE優先順位追加
      if(has_position && !has_oco_orders)
      {
         // BE判定（最小）
         if(IsBreakEvenReached())
         {
            action.type = ACTION_BE_APPLY;
            action.reason = "BE trigger reached";
            Print("[Aegis-TRACE][Decision] return Action=ACTION_BE_APPLY");
            return action;
         }

         // 何もしない（BE未達）
         action.type = ACTION_NONE;
         action.reason = "Hold position (BE not reached)";
         Print("[Aegis-TRACE][Decision] return Action=ACTION_NONE (holding for BE)");
         return action;
      }

      // ========== 優先順位3: MODIFY（OCO注文存在） ==========
      if(has_oco_orders)
      {
         // OCO配置距離を取得
         double distance_points = data.GetOCODistancePoints();

         // ★Phase C-2.5: window_high/low を基準に価格計算
         double new_buy_price  = NormalizeDouble(window_high + distance_points * point, digits);
         double new_sell_price = NormalizeDouble(window_low - distance_points * point, digits);

         // ★Phase C-4.3: MODIFY時のSL/TP再計算（必須）
         double initial_sl_points = data.GetInitialSLPoints();
         double initial_tp_points = data.GetInitialTPPoints();
         
         action.type = ACTION_OCO_MODIFY;
         action.buy_price  = new_buy_price;
         action.sell_price = new_sell_price;
         action.sl = initial_sl_points * point;  // Phase C-4.3: SL再計算
         action.tp = initial_tp_points * point;  // Phase C-4.3: TP再計算
         action.reason = "OCO_MODIFY: Price follow";
         /*DEBUG*/
         Print("[Aegis-TRACE][Decision][MODIFY]",
               " window_high=", window_high,
               " window_low=", window_low,
               " point=", point,
               " digits=", digits,
               " dist=", distance_points,
               " new_buy_price=", new_buy_price,
               " new_sell_price=", new_sell_price,
               " sl=", action.sl, " (", initial_sl_points/10.0, "pips)",
               " tp=", action.tp, " (", initial_tp_points/10.0, "pips)");
         /*DEBUG*/

         // target_ticketは後回し（フェーズF-4では未使用）
         action.target_ticket = 0;

         Print("[Aegis-TRACE][Decision] return Action=ACTION_OCO_MODIFY");
         return action;
      }

      // ========== 優先順位4: PLACE（エントリー可能） ==========
      bool entry_clear = data.GetObs_EntryClear();

      // ★★★ トレースログ: entry_clear判定 ★★★
      Print("[Aegis-TRACE][Decision] entry_clear=", entry_clear);

      if(entry_clear)
      {
         // OCO配置距離を取得
         double distance_points = data.GetOCODistancePoints();

         // ★Phase C-2.5: window_high/low を基準に価格計算
         // BuyStop価格 = WindowHigh + 距離
         double buy_price  = NormalizeDouble(window_high + distance_points * point, digits);

         // SellStop価格 = WindowLow - 距離
         double sell_price = NormalizeDouble(window_low - distance_points * point, digits);

         // ★★★ トレースログ: ACTION_OCO_PLACE生成 ★★★
         Print("[Aegis-TRACE][Decision] ACTION_OCO_PLACE: buy_price=", buy_price, " sell_price=", sell_price, " lot=", data.GetOCOLot());

         // ★Phase C-4.1: 初期SL/TP計算（必須）
         double initial_sl_points = data.GetInitialSLPoints();
         double initial_tp_points = data.GetInitialTPPoints();
         
         action.type = ACTION_OCO_PLACE;
         action.buy_price  = buy_price;
         action.sell_price = sell_price;
         action.lot = data.GetOCOLot();
         action.sl = initial_sl_points * point;  // Phase C-4.1: 初期SL使用
         action.tp = initial_tp_points * point;  // Phase C-4.1: 初期TP使用
         action.reason = "OCO_PLACE: Entry condition met";

         /*DEBUG*/
         Print("[Aegis-TRACE][Decision][PLACE]",
               " window_high=", window_high,
               " window_low=", window_low,
               " dist=", distance_points,
               " point=", point,
               " digits=", digits,
               " buy_price=", buy_price,
               " sell_price=", sell_price,
               " action.lot=", action.lot,
               " action.sl=", action.sl, " (", initial_sl_points/10.0, "pips)",
               " action.tp=", action.tp, " (", initial_tp_points/10.0, "pips)",
               " action.reason=", action.reason);
         /*DEBUG*/

         Print("[Aegis-TRACE][Decision] return Action=ACTION_OCO_PLACE");
         return action;
      }

      // ========== 優先順位5: NONE（何もしない） ==========
      action.type = ACTION_NONE;
      action.reason = "No action required";
      Print("[Aegis-TRACE][Decision] return Action=ACTION_NONE (entry_clear=false)");

      return action;
   }

   //-------------------------------------------------------------------
   //| 最後に取得したエントリー可能状態を取得                               |
   //| [戻り値]                                                          |
   //|   true  : エントリー可能                                           |
   //|   false : エントリー不可                                           |
   //| [Note]                                                            |
   //|   フェーズBでは参照用のみ                                          |
   //-------------------------------------------------------------------
   bool GetLastEntryClear() const
   {
      return m_last_entry_clear;
   }
};

//+------------------------------------------------------------------+
//| End of CDecisionOCOFollow.mqh                                    |
//+------------------------------------------------------------------+
