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

//+------------------------------------------------------------------+
//| Class   : CDecisionOCOFollow                                     |
//| Layer   : Decision                                               |
//| Purpose : 追従型OCO戦略の判断層（フェーズB: 最小実装）              |
//+------------------------------------------------------------------+
class CDecisionOCOFollow : public CDecisionBase
{
private:
   bool m_last_entry_clear;  // 最後に取得したエントリー可能状態

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
      bool has_position   = (PositionsTotal() > 0);

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

      // ========== 優先順位2: CANCEL（ポジションのみ、OCO無し） ==========
      if(has_position)
      {
         action.type = ACTION_OCO_CANCEL;
         action.reason = "OCO_CANCEL: Position detected";
         Print("[Aegis-TRACE][Decision] return Action=ACTION_OCO_CANCEL");
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
