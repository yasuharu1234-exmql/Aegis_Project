//+------------------------------------------------------------------+
//| File    : CExecutionManager.mqh                                  |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Execution                                              |
//|                                                                  |
//| Role                                                             |
//|  - Strategy層から渡された実行要求を処理する                      |
//|  - OrderSend / Modify / Close 等の「実行のみ」を担当             |
//|                                                                  |
//| Phase 3 Notes                                                    |
//|  - ダミー実装を削除し、実際のOrderSendを呼び出す                  |
//|  - exMQL::IsFatalError() で致命的エラーを判定                    |
//|  - ログが充実                                                    |
//|                                                                  |
//| Phase 6 Task 2 - Phase 3                                         |
//|  - 実行層ログ追加（MODIFY_TRY/OK/FAIL, CANCEL_OK）               |
//|  - 計8箇所のログ挿入                                             |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CExecutionBase.mqh"
#include "../../EXMQL/EXMQL.mqh"  // Phase 3: OrderSend/IsFatalError使用のため

//+------------------------------------------------------------------+
//| Class   : CExecutionManager                                      |
//+------------------------------------------------------------------+
class CExecutionManager : public CExecutionBase
{
private:
   // ★Phase C-4.2: イベントログ用の変化検知
   int m_prev_positions_total;  // 前Tickのポジション数
   int m_prev_orders_total;     // 前Tickの注文数
   
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CExecutionManager(int magic_number, int slippage = 3)
      : CExecutionBase(magic_number, slippage)
   {
      // ★Phase C-4.2: 変化検知用初期化
      m_prev_positions_total = 0;
      m_prev_orders_total = 0;
   }

   //-------------------------------------------------------------------+
   //| 初期化                                                            |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CExecutionBase::Init())
      {
         Print("[ExecutionManager] ベースクラス初期化失敗");
         return false;
      }

      Print("[ExecutionManager] Phase 3 実装初期化完了");
      return true;
   }

   //-------------------------------------------------------------------+
   //| 終了処理                                                          |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[ExecutionManager] 終了処理");
      CExecutionBase::Deinit();
   }

   //-------------------------------------------------------------------+
   //| メイン処理（Tick毎に呼び出し）                                     |
   //-------------------------------------------------------------------
   bool Execute(CLA_Data &data, ulong tick_id)
   {
      // ========== Phase C-4.2: ポジション変化検知 ==========
      int current_positions = PositionsTotal();
      int current_orders = OrdersTotal();
      
      // 約定発生検知（ポジション数が増えた）
      if(current_positions > m_prev_positions_total)
      {
         DetectFill(current_positions);
      }
      
      // 前回値を更新
      m_prev_positions_total = current_positions;
      m_prev_orders_total = current_orders;
      
      // ========== 状態チェック ==========
      ENUM_EXEC_STATE current_state = data.GetExecState();

      // 再入防止
      if(current_state == EXEC_STATE_IN_PROGRESS)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "処理中のため再入禁止", tick_id);
         return true;
      }

      // ========== 操作要求の取得 ==========
      ENUM_EXEC_REQUEST request = data.GetExecRequest();

      if(request == EXEC_REQ_NONE)
      {
         if(current_state != EXEC_STATE_IDLE)
         {
            data.SetExecState(EXEC_STATE_IDLE, tick_id, "要求なし");
         }
         return true;
      }

      // ========== 状態遷移: IDLE → IN_PROGRESS ==========
      data.SetExecState(EXEC_STATE_IN_PROGRESS, tick_id,
                        StringFormat("要求処理開始: %s", EnumToString(request)));

      // ========== 操作要求のハンドリング（Phase 3: 実装） ==========
      bool success = false;

      switch(request)
      {
      case EXEC_REQ_PLACE:
         success = HandlePlace(data, tick_id);
         break;

      case EXEC_REQ_MODIFY:
         success = HandleModify(data, tick_id);
         break;

      case EXEC_REQ_CANCEL:
         success = HandleCancel(data, tick_id);
         break;

      case EXEC_REQ_CLOSE:
         success = HandleClose(data, tick_id);
         break;

      default:
         data.SetExecResult(EXEC_RESULT_REJECTED, "未知の操作要求", tick_id);
         data.SetExecState(EXEC_STATE_FAILED, tick_id, "未知の要求");
         return true;
      }

      // ========== 状態遷移: IN_PROGRESS → APPLIED/FAILED ==========
      if(success)
      {
         data.SetExecState(EXEC_STATE_APPLIED, tick_id, "処理成功");
      }
      else
      {
         data.SetExecState(EXEC_STATE_FAILED, tick_id, "処理失敗");
      }

      // 要求クリア
      data.SetExecRequest(EXEC_REQ_NONE, tick_id);

      return true;
   }


   //-------------------------------------------------------------------
   //| フェーズD追加: Action受け取り入口（最小接続）                       |
   //| [引数]                                                            |
   //|   action  : Decision Arbiterから返された最終Action                |
   //|   data    : システム共通データ                                     |
   //|   tick_id : この操作のユニークID                                   |
   //| [戻り値]                                                          |
   //|   true  : 処理完了                                                |
   //|   false : 処理失敗                                                |
   //|                                                                  |
   //| [Design Philosophy]                                               |
   //|   - Action → 実行命令への最小マッピング                            |
   //|   - フェーズDでは「つながること」のみが目的                         |
   //|   - ダミー実装OK、正しさは問わない                                 |
   //|                                                                  |
   //| [Mapping]                                                         |
   //|   ACTION_NONE       → 何もしない（これも正当な処理）               |
   //|   ACTION_OCO_PLACE  → ダミー実行（フェーズE以降で本実装）           |
   //|   ACTION_OCO_MODIFY → ダミー実行（フェーズE以降で本実装）           |
   //|   ACTION_OCO_CANCEL → ダミー実行（フェーズE以降で本実装）           |
   //-------------------------------------------------------------------
   bool ExecuteAction(const Action &action, CLA_Data &data, ulong tick_id)
   {
      // ★★★ トレースログ: ExecuteAction開始 ★★★
      Print("[Aegis-TRACE][Execution] === ExecuteAction START ===");
      Print("[Aegis-TRACE][Execution] Action.type=", action.type);
      Print("[Aegis-TRACE][Execution] buy_price=", action.buy_price, " sell_price=", action.sell_price);
      Print("[Aegis-TRACE][Execution] lot=", action.lot, " sl=", action.sl, " tp=", action.tp);

      // ========== Action種別によるマッピング ==========
      switch(action.type)
      {
      case ACTION_NONE:
         // 何もしない（これも正当なAction処理）
         // Phase C-4.2: ACTION_NONEログは InpEnableTraceSpam 時のみ
         if(InpEnableTraceSpam)
         {
            Print("[ExecutionManager] Action: NONE（何もしない）");
         }
         return true;

      case ACTION_OCO_PLACE:
         // ★フェーズG-1: 本実装（最小版）
      {
         // Actionから値を取得
         double buy_price  = action.buy_price;
         double sell_price = action.sell_price;
         double lot        = action.lot;
         double sl         = action.sl;
         double tp         = action.tp;

         // 価格情報取得
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

         // ★★★ トレースログ: 価格妥当性確認 ★★★
         Print("[Aegis-TRACE][Execution] === BuyStop配置前チェック ===");
         Print("[Aegis-TRACE][Execution] Symbol: _Symbol=", _Symbol, " Symbol()=", Symbol());
         Print("[Aegis-TRACE][Execution] ask=", ask, " bid=", bid, " point=", point, " digits=", digits);
         Print("[Aegis-TRACE][Execution] buy_price=", buy_price, " sell_price=", sell_price);
         Print("[Aegis-TRACE][Execution] lot=", lot, " sl=", sl/point, "points (", sl/point/10.0, "pips)", " tp=", tp/point, "points (", tp/point/10.0, "pips)");

         // 価格妥当性チェック
         if(buy_price <= ask)
         {
            Print("[Aegis-TRACE][Execution] ❌ 価格エラー: buy_price(", buy_price, ") <= ask(", ask, ")");
         }
         if(sell_price >= bid)
         {
            Print("[Aegis-TRACE][Execution] ❌ 価格エラー: sell_price(", sell_price, ") >= bid(", bid, ")");
         }

         // SL/TP を価格に変換
         double buy_sl  = (sl > 0) ? NormalizeDouble(buy_price - sl, digits) : 0;
         double buy_tp  = (tp > 0) ? NormalizeDouble(buy_price + tp, digits) : 0;
         double sell_sl = (sl > 0) ? NormalizeDouble(sell_price + sl, digits) : 0;
         double sell_tp = (tp > 0) ? NormalizeDouble(sell_price - tp, digits) : 0;

         // ========== BuyStop 配置 ==========
         MqlTradeRequest request_buy = {};
         MqlTradeResult  result_buy  = {};

         request_buy.action = TRADE_ACTION_PENDING;
         request_buy.symbol = _Symbol;
         request_buy.volume = lot;
         request_buy.type   = ORDER_TYPE_BUY_STOP;
         request_buy.price  = buy_price;
         request_buy.sl     = buy_sl;
         request_buy.tp     = buy_tp;
         request_buy.magic     = m_magic_number;        // ★追加
         request_buy.deviation = m_slippage;            // ★追加
         request_buy.type_time = ORDER_TIME_GTC;        // ★追加
         request_buy.type_filling = ORDER_FILLING_RETURN; // ★追加
         request_buy.comment = "Aegis_OCO_Buy";

         // ★★★ トレースログ: リクエスト内容 ★★★
         Print("[Aegis-TRACE][Execution] BuyStop Request:");
         Print("[Aegis-TRACE][Execution]   magic=", request_buy.magic);
         Print("[Aegis-TRACE][Execution]   deviation=", request_buy.deviation);
         Print("[Aegis-TRACE][Execution]   type_time=", request_buy.type_time);
         Print("[Aegis-TRACE][Execution]   type_filling=", request_buy.type_filling);

         bool buy_success = exMQL.OrderSend(request_buy, result_buy);

         // ★★★ トレースログ: 結果詳細 ★★★
         Print("[Aegis-TRACE][Execution] BuyStop Result:");
         Print("[Aegis-TRACE][Execution]   success=", buy_success);
         Print("[Aegis-TRACE][Execution]   retcode=", result_buy.retcode);
         Print("[Aegis-TRACE][Execution]   order=", result_buy.order);
         Print("[Aegis-TRACE][Execution]   comment=", result_buy.comment);
         Print("[Aegis-TRACE][Execution]   GetLastError()=", GetLastError());

         if(!buy_success)
         {
            Print("❌ [実行層] BuyStop配置失敗: ", GetLastError());
            data.SetExecResult(EXEC_RESULT_REJECTED, "BuyStop配置失敗", tick_id);
            return false;
         }

         ulong buy_ticket = result_buy.order;
         Print("✅ [実行層] BuyStop配置成功: チケット=", buy_ticket, " 価格=", buy_price);

         // ========== SellStop 配置 ==========
         MqlTradeRequest request_sell = {};
         MqlTradeResult  result_sell  = {};

         request_sell.action = TRADE_ACTION_PENDING;
         request_sell.symbol = _Symbol;
         request_sell.volume = lot;
         request_sell.type   = ORDER_TYPE_SELL_STOP;
         request_sell.price  = sell_price;
         request_sell.sl     = sell_sl;
         request_sell.tp     = sell_tp;
         request_sell.magic     = m_magic_number;        // ★追加
         request_sell.deviation = m_slippage;            // ★追加
         request_sell.type_time = ORDER_TIME_GTC;        // ★追加
         request_sell.type_filling = ORDER_FILLING_RETURN; // ★追加
         request_sell.comment = "Aegis_OCO_Sell";

         // ★★★ トレースログ: リクエスト内容 ★★★
         Print("[Aegis-TRACE][Execution] SellStop Request:");
         Print("[Aegis-TRACE][Execution]   magic=", request_sell.magic);
         Print("[Aegis-TRACE][Execution]   deviation=", request_sell.deviation);
         Print("[Aegis-TRACE][Execution]   type_time=", request_sell.type_time);
         Print("[Aegis-TRACE][Execution]   type_filling=", request_sell.type_filling);

         bool sell_success = exMQL.OrderSend(request_sell, result_sell);

         // ★★★ トレースログ: 結果詳細 ★★★
         Print("[Aegis-TRACE][Execution] SellStop Result:");
         Print("[Aegis-TRACE][Execution]   success=", sell_success);
         Print("[Aegis-TRACE][Execution]   retcode=", result_sell.retcode);
         Print("[Aegis-TRACE][Execution]   order=", result_sell.order);
         Print("[Aegis-TRACE][Execution]   comment=", result_sell.comment);
         Print("[Aegis-TRACE][Execution]   GetLastError()=", GetLastError());

         if(!sell_success)
         {
            Print("❌ [実行層] SellStop配置失敗: ", GetLastError());
            // ★フェーズH-1: BuyStopロールバック
            Print("⚠️ [実行層] SellStop失敗によりBuyStopをロールバック: チケット=", buy_ticket);

            MqlTradeRequest rollback_request = {};
            MqlTradeResult  rollback_result  = {};

            rollback_request.action = TRADE_ACTION_REMOVE;
            rollback_request.order  = buy_ticket;

            bool rollback_success = exMQL.OrderSend(rollback_request, rollback_result);

            if(rollback_success)
            {
               Print("✅ [実行層] BuyStopロールバック成功");
            }
            else
            {
               Print("❌ [実行層] BuyStopロールバック失敗: ", GetLastError());
            }
            data.SetExecResult(EXEC_RESULT_REJECTED, "SellStop配置失敗", tick_id);
            return false;
         }

         ulong sell_ticket = result_sell.order;
         Print("✅ [実行層] SellStop配置成功: チケット=", sell_ticket, " 価格=", sell_price);

         // チケット記録
         data.SetOCOBuyTicket(buy_ticket);
         data.SetOCOSellTicket(sell_ticket);
         data.SetOCOBuyPrice(buy_price);
         data.SetOCOSellPrice(sell_price);

         // 成功
         Print("✅ [実行層] OCO配置完了");
         data.SetExecResult(EXEC_RESULT_SUCCESS, "OCO配置成功", tick_id);
         
         // ★Phase C-4.2: PLACE後の孤児検出
         DetectOrphanOrders();
         
         return true;
      }
      case ACTION_OCO_MODIFY:
         // ★Phase C-4.3: SL/TP再計算・再設定
      {
         // ★Phase C-4.3: Actionから価格とSL/TPを取得
         double new_buy_price  = action.buy_price;
         double new_sell_price = action.sell_price;
         double sl_distance = action.sl;  // Phase C-4.3: 判断層で計算済み
         double tp_distance = action.tp;  // Phase C-4.3: 判断層で計算済み

         // ★Phase C-4.3: SL/TP安全装置
         if(sl_distance == 0.0 || tp_distance == 0.0)
         {
            Print("❌ [Aegis-EVENT][ERROR] MODIFY: SL/TP未設定 sl=", sl_distance, " tp=", tp_distance);
            data.SetExecResult(EXEC_RESULT_REJECTED, "MODIFY: SL/TP未設定", tick_id);
            return false;
         }

         double current_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         int current_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

         // ★Phase C-4.3: SL/TPを価格に変換
         double new_buy_sl  = NormalizeDouble(new_buy_price - sl_distance, current_digits);
         double new_buy_tp  = NormalizeDouble(new_buy_price + tp_distance, current_digits);
         double new_sell_sl = NormalizeDouble(new_sell_price + sl_distance, current_digits);
         double new_sell_tp = NormalizeDouble(new_sell_price - tp_distance, current_digits);

         // チケット取得
         ulong buy_ticket  = data.GetOCOBuyTicket();
         ulong sell_ticket = data.GetOCOSellTicket();

         bool buy_success = true;
         bool sell_success = true;

         // ========== BuyStop変更 ==========
         if(buy_ticket > 0)
         {
            MqlTradeRequest request_buy = {};
            MqlTradeResult  result_buy  = {};

            request_buy.action = TRADE_ACTION_MODIFY;
            request_buy.order  = buy_ticket;
            request_buy.price  = new_buy_price;
            request_buy.sl     = new_buy_sl;  // ★Phase C-4.3: SL設定
            request_buy.tp     = new_buy_tp;  // ★Phase C-4.3: TP設定

            buy_success = exMQL.OrderSend(request_buy, result_buy);

            if(!buy_success)
            {
               Print("❌ [実行層] BuyStop変更失敗: チケット=", buy_ticket, " エラー=", GetLastError());
            }
            else
            {
               Print("✅ [実行層] BuyStop変更成功: チケット=", buy_ticket, " 新価格=", new_buy_price);
               Print("[Aegis-EVENT][MODIFY] ticket=", buy_ticket, " price=", new_buy_price, " sl=", new_buy_sl, " tp=", new_buy_tp);
               data.SetOCOBuyPrice(new_buy_price);
            }
         }

         // ========== SellStop変更 ==========
         if(sell_ticket > 0)
         {
            MqlTradeRequest request_sell = {};
            MqlTradeResult  result_sell  = {};

            request_sell.action = TRADE_ACTION_MODIFY;
            request_sell.order  = sell_ticket;
            request_sell.price  = new_sell_price;
            request_sell.sl     = new_sell_sl;  // ★Phase C-4.3: SL設定
            request_sell.tp     = new_sell_tp;  // ★Phase C-4.3: TP設定

            sell_success = exMQL.OrderSend(request_sell, result_sell);

            if(!sell_success)
            {
               Print("❌ [実行層] SellStop変更失敗: チケット=", sell_ticket, " エラー=", GetLastError());
            }
            else
            {
               Print("✅ [実行層] SellStop変更成功: チケット=", sell_ticket, " 新価格=", new_sell_price);
               Print("[Aegis-EVENT][MODIFY] ticket=", sell_ticket, " price=", new_sell_price, " sl=", new_sell_sl, " tp=", new_sell_tp);
               data.SetOCOSellPrice(new_sell_price);
            }
         }

         // 結果判定（どちらか成功すればOK）
         if(buy_success || sell_success)
         {
            Print("✅ [実行層] OCO変更完了");
            data.SetExecResult(EXEC_RESULT_SUCCESS, "OCO変更成功", tick_id);
            return true;
         }
         else
         {
            Print("❌ [実行層] OCO変更失敗（両方失敗）");
            data.SetExecResult(EXEC_RESULT_REJECTED, "OCO変更失敗", tick_id);
            return false;
         }
      }

      case ACTION_OCO_CANCEL:
         // ★フェーズG-2: 本実装（最小版）
      {
         // チケット取得
         ulong buy_ticket  = data.GetOCOBuyTicket();
         ulong sell_ticket = data.GetOCOSellTicket();

         // どちらか片方をキャンセル（簡易実装: Buyを優先）
         ulong target_ticket = 0;
         if(buy_ticket > 0)
         {
            target_ticket = buy_ticket;
         }
         else if(sell_ticket > 0)
         {
            target_ticket = sell_ticket;
         }

         if(target_ticket == 0)
         {
            Print("⚠️ [実行層] OCO取消: キャンセル対象チケットなし");
            data.SetExecResult(EXEC_RESULT_SUCCESS, "キャンセル対象なし", tick_id);
            return true;
         }
         // OrderDelete実行（TRADE_ACTION_REMOVE）
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};

         request.action = TRADE_ACTION_REMOVE;
         request.order  = target_ticket;

         bool success = exMQL.OrderSend(request, result);

         if(!success)
         {
            Print("❌ [実行層] OCO取消失敗: チケット=", target_ticket, " エラー=", GetLastError());
            data.SetExecResult(EXEC_RESULT_REJECTED, "OCO取消失敗", tick_id);
            return false;
         }

         Print("✅ [実行層] OCO取消成功: チケット=", target_ticket);

         // チケットクリア（簡易実装: 両方クリア）
         data.SetOCOBuyTicket(0);
         data.SetOCOSellTicket(0);

         data.SetExecResult(EXEC_RESULT_SUCCESS, "OCO取消成功", tick_id);
         return true;
      }

      default:
         // 未知のAction種別
         Print("[ExecutionManager] 警告: 未知のAction種別: ", action.type);
         data.SetExecResult(EXEC_RESULT_INVALID_PARAMS, "未知のAction", tick_id);
         return false;
      }
   }

private:
   //-------------------------------------------------------------------
   //| OCO注文配置処理（Phase 3: 実装）                                   |
   //-------------------------------------------------------------------
   bool HandlePlace(CLA_Data &data, ulong tick_id)
   {
      double ask   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double bid   = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      int    digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

      // ★外部から指定された配置条件を取得
      double buy_price  = data.GetOCOBuyPrice();    // ★Phase 2: データ層から取得
      double sell_price = data.GetOCOSellPrice();   // ★Phase 2: データ層から取得
      double lot_size   = data.GetOCOLot();         // ★Phase 2: データ層から取得
      int    sl_points  = (int)data.GetOCOSLPoints();  // ★Phase 5: SL取得
      int    tp_points  = (int)data.GetOCOTPPoints();  // ★Phase 5: TP取得

      // ★Phase 5: SL/TP計算
      double buy_sl  = (sl_points > 0) ? NormalizeDouble(buy_price  - sl_points * point, digits) : 0;
      double buy_tp  = (tp_points > 0) ? NormalizeDouble(buy_price  + tp_points * point, digits) : 0;
      double sell_sl = (sl_points > 0) ? NormalizeDouble(sell_price + sl_points * point, digits) : 0;
      double sell_tp = (tp_points > 0) ? NormalizeDouble(sell_price - tp_points * point, digits) : 0;

      // 配置条件の検証
      if(buy_price <= ask)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED,
                            StringFormat("BuyStop配置失敗: 価格不正 (Buy=%.5f <= Ask=%.5f)", buy_price, ask), tick_id);
         return false;
      }

      if(sell_price >= bid)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED,
                            StringFormat("SellStop配置失敗: 価格不正 (Sell=%.5f >= Bid=%.5f)", sell_price, bid), tick_id);
         return false;
      }

      // ========== BuyStop 配置 ==========
      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};

      request.action    = TRADE_ACTION_PENDING;
      request.symbol    = Symbol();
      request.volume    = lot_size;
      request.type      = ORDER_TYPE_BUY_STOP;
      request.price     = buy_price;
      request.sl        = buy_sl;   // ★Phase 5: SL設定
      request.tp        = buy_tp;   // ★Phase 5: TP設定
      request.deviation = m_slippage;
      request.magic     = m_magic_number;
      request.comment   = "OCO_BuyStop";

      if(!exMQL.OrderSend(request, result))
      {
         int error_code = GetLastError();
         data.SetExecResult(EXEC_RESULT_FATAL_ERROR,
                            StringFormat("BuyStop配置失敗: エラーコード=%d", error_code), tick_id);
         Print("[ExecutionManager] BuyStop配置失敗: ", error_code);
         return false;
      }

      ulong buy_ticket = result.order;
      Print("[ExecutionManager] BuyStop配置成功: Ticket=", buy_ticket, " Price=", buy_price);

      // ========== SellStop 配置 ==========
      request.type    = ORDER_TYPE_SELL_STOP;
      request.price   = sell_price;
      request.sl      = sell_sl;  // ★Phase 5: SL設定
      request.tp      = sell_tp;  // ★Phase 5: TP設定
      request.comment = "OCO_SellStop";

      if(!exMQL.OrderSend(request, result))
      {
         int error_code = GetLastError();
         data.SetExecResult(EXEC_RESULT_FATAL_ERROR,
                            StringFormat("SellStop配置失敗: エラーコード=%d", error_code), tick_id);
         Print("[ExecutionManager] SellStop配置失敗: ", error_code);

         // BuyStopのロールバック試行
         MqlTradeRequest cancel_req = {};
         MqlTradeResult  cancel_res = {};
         cancel_req.action = TRADE_ACTION_REMOVE;
         cancel_req.order  = buy_ticket;
         exMQL.OrderSend(cancel_req, cancel_res);

         return false;
      }

      ulong sell_ticket = result.order;
      Print("[ExecutionManager] SellStop配置成功: Ticket=", sell_ticket, " Price=", sell_price);

      // チケット番号を保存
      data.SetOCOBuyTicket(buy_ticket);
      data.SetOCOSellTicket(sell_ticket);

      // ★Phase 4: 前回注文配置/変更時刻を更新
      data.SetLastOrderActionTime(TimeCurrent());

      data.SetExecResult(EXEC_RESULT_SUCCESS,
                         StringFormat("OCO配置成功: Buy#%d Sell#%d", buy_ticket, sell_ticket), tick_id);
      return true;
   }

   //-------------------------------------------------------------------
   //| 注文価格変更処理（Phase 3: 実装）                                  |
   //-------------------------------------------------------------------
   bool HandleModify(CLA_Data &data, ulong tick_id)
   {
      ulong buy_ticket  = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      double buy_price  = data.GetOCOBuyPrice();
      double sell_price = data.GetOCOSellPrice();

      // ★Phase 5: SL/TP再計算用パラメータ取得
      int    sl_points = (int)data.GetOCOSLPoints();
      int    tp_points = (int)data.GetOCOTPPoints();
      double point     = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      int    digits    = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

      bool modified = false;

      // BuyStop MODIFY
      if(buy_ticket > 0)
      {
         if(exMQL.OrderSelect(buy_ticket))
         {
            // ★Phase 6 Task 2 - Phase 3: MODIFY_TRYログ（BuyStop）
            if(InpEnableStateLog)
            {
               data.AddLogEx(
                  LOG_ID_MODIFY_TRY,
                  "MODIFY_TRY",
                  IntegerToString(buy_ticket),
                  DoubleToString(exMQL.OrderGetDouble(ORDER_PRICE_OPEN), digits),
                  DoubleToString(buy_price, digits),
                  "",
                  "BuyStop価格変更試行",
                  false
               );
            }

            // ★Phase 5: 新価格に合わせてSL/TPを再計算
            double new_buy_sl = (sl_points > 0) ? NormalizeDouble(buy_price - sl_points * point, digits) : 0;
            double new_buy_tp = (tp_points > 0) ? NormalizeDouble(buy_price + tp_points * point, digits) : 0;

            MqlTradeRequest request = {};
            MqlTradeResult  result  = {};

            request.action = TRADE_ACTION_MODIFY;
            request.order  = buy_ticket;
            request.price  = buy_price;
            request.sl     = new_buy_sl;  // ★Phase 5: 再計算したSL
            request.tp     = new_buy_tp;  // ★Phase 5: 再計算したTP

            if(!exMQL.OrderSend(request, result))
            {
               int error_code = GetLastError();
               Print("[ExecutionManager] BuyStop MODIFY失敗: ", error_code);

               // ★Phase 6 Task 2 - Phase 3: MODIFY_FAILログ（BuyStop）
               if(InpEnableStateLog)
               {
                  data.AddLogEx(
                     LOG_ID_MODIFY_FAIL,
                     "MODIFY_FAIL",
                     IntegerToString(buy_ticket),
                     DoubleToString(buy_price, digits),
                     IntegerToString(error_code),
                     "",
                     StringFormat("BuyStop価格変更失敗 error=%d", error_code),
                     false
                  );
               }

               if(exMQL.IsFatalError(error_code))
               {
                  data.SetExecResult(EXEC_RESULT_FATAL_ERROR,
                                     StringFormat("BuyStop MODIFY失敗（致命的）: %d", error_code), tick_id);
                  return false;
               }
            }
            else
            {
               // ★Phase 6 Task 2 - Phase 3: MODIFY_OKログ（BuyStop）
               if(InpEnableStateLog)
               {
                  data.AddLogEx(
                     LOG_ID_MODIFY_OK,
                     "MODIFY_OK",
                     IntegerToString(buy_ticket),
                     DoubleToString(buy_price, digits),
                     "",
                     "",
                     "BuyStop価格変更成功",
                     false
                  );
               }

               modified = true;
            }
         }
      }

      // SellStop MODIFY
      if(sell_ticket > 0)
      {
         if(exMQL.OrderSelect(sell_ticket))
         {
            // ★Phase 6 Task 2 - Phase 3: MODIFY_TRYログ（SellStop）
            if(InpEnableStateLog)
            {
               data.AddLogEx(
                  LOG_ID_MODIFY_TRY,
                  "MODIFY_TRY",
                  IntegerToString(sell_ticket),
                  DoubleToString(exMQL.OrderGetDouble(ORDER_PRICE_OPEN), digits),
                  DoubleToString(sell_price, digits),
                  "",
                  "SellStop価格変更試行",
                  false
               );
            }

            // ★Phase 5: 新価格に合わせてSL/TPを再計算
            double new_sell_sl = (sl_points > 0) ? NormalizeDouble(sell_price + sl_points * point, digits) : 0;
            double new_sell_tp = (tp_points > 0) ? NormalizeDouble(sell_price - tp_points * point, digits) : 0;

            MqlTradeRequest request = {};
            MqlTradeResult  result  = {};

            request.action = TRADE_ACTION_MODIFY;
            request.order  = sell_ticket;
            request.price  = sell_price;
            request.sl     = new_sell_sl;  // ★Phase 5: 再計算したSL
            request.tp     = new_sell_tp;  // ★Phase 5: 再計算したTP

            if(!exMQL.OrderSend(request, result))
            {
               int error_code = GetLastError();
               Print("[ExecutionManager] SellStop MODIFY失敗: ", error_code);

               // ★Phase 6 Task 2 - Phase 3: MODIFY_FAILログ（SellStop）
               if(InpEnableStateLog)
               {
                  data.AddLogEx(
                     LOG_ID_MODIFY_FAIL,
                     "MODIFY_FAIL",
                     IntegerToString(sell_ticket),
                     DoubleToString(sell_price, digits),
                     IntegerToString(error_code),
                     "",
                     StringFormat("SellStop価格変更失敗 error=%d", error_code),
                     false
                  );
               }

               if(exMQL.IsFatalError(error_code))
               {
                  data.SetExecResult(EXEC_RESULT_FATAL_ERROR,
                                     StringFormat("SellStop MODIFY失敗（致命的）: %d", error_code), tick_id);
                  return false;
               }
            }
            else
            {
               // ★Phase 6 Task 2 - Phase 3: MODIFY_OKログ（SellStop）
               if(InpEnableStateLog)
               {
                  data.AddLogEx(
                     LOG_ID_MODIFY_OK,
                     "MODIFY_OK",
                     IntegerToString(sell_ticket),
                     DoubleToString(sell_price, digits),
                     "",
                     "",
                     "SellStop価格変更成功",
                     false
                  );
               }

               modified = true;
            }
         }
      }

      if(modified)
      {
         Print("[ExecutionManager] MODIFY成功: Buy@", buy_price, " Sell@", sell_price);
         data.SetExecResult(EXEC_RESULT_SUCCESS,
                            StringFormat("MODIFY成功: Buy@%.5f Sell@%.5f", buy_price, sell_price), tick_id);

         // ★Phase 4: 前回注文配置/変更時刻を更新
         data.SetLastOrderActionTime(TimeCurrent());
      }
      else
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "MODIFY失敗", tick_id);
      }

      return true;
   }

   //-------------------------------------------------------------------
   //| 注文取消処理（Phase 3: 実装）                                      |
   //-------------------------------------------------------------------
   bool HandleCancel(CLA_Data &data, ulong tick_id)
   {
      ulong buy_ticket  = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();

      bool cancelled = false;

      // BuyStop CANCEL
      if(buy_ticket > 0 && exMQL.OrderSelect(buy_ticket))
      {
         // ★Phase C-4.2: OCOキャンセル要求ログ
         Print("[Aegis-EVENT][OCO] cancel request ticket=", buy_ticket, " (BuyStop)");
         
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};

         request.action = TRADE_ACTION_REMOVE;
         request.order  = buy_ticket;

         if(!exMQL.OrderSend(request, result))
         {
            int error_code = GetLastError();
            Print("[ExecutionManager] BuyStop CANCEL失敗: ", error_code);
            // ★Phase C-4.2: キャンセル失敗ログ
            Print("[Aegis-EVENT][OCO] cancel result success=false retcode=", result.retcode,
                  " lasterr=", error_code);
         }
         else
         {
            // ★Phase C-4.2: キャンセル成功ログ
            Print("[Aegis-EVENT][OCO] cancel result success=true ticket=", buy_ticket);
            
            // ★Phase 6 Task 2 - Phase 3: CANCEL_OKログ（BuyStop）
            if(InpEnableStateLog)
            {
               data.AddLogEx(
                  LOG_ID_CANCEL_OK,
                  "CANCEL_OK",
                  IntegerToString(buy_ticket),
                  "",
                  "",
                  "",
                  "BuyStop注文取消成功",
                  false
               );
            }

            data.SetOCOBuyTicket(0);
            cancelled = true;
         }
      }

      // SellStop CANCEL
      if(sell_ticket > 0 && exMQL.OrderSelect(sell_ticket))
      {
         // ★Phase C-4.2: OCOキャンセル要求ログ
         Print("[Aegis-EVENT][OCO] cancel request ticket=", sell_ticket, " (SellStop)");
         
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};

         request.action = TRADE_ACTION_REMOVE;
         request.order  = sell_ticket;

         if(!exMQL.OrderSend(request, result))
         {
            int error_code = GetLastError();
            Print("[ExecutionManager] SellStop CANCEL失敗: ", error_code);
            // ★Phase C-4.2: キャンセル失敗ログ
            Print("[Aegis-EVENT][OCO] cancel result success=false retcode=", result.retcode,
                  " lasterr=", error_code);
         }
         else
         {
            // ★Phase C-4.2: キャンセル成功ログ
            Print("[Aegis-EVENT][OCO] cancel result success=true ticket=", sell_ticket);
            
            // ★Phase 6 Task 2 - Phase 3: CANCEL_OKログ（SellStop）
            if(InpEnableStateLog)
            {
               data.AddLogEx(
                  LOG_ID_CANCEL_OK,
                  "CANCEL_OK",
                  IntegerToString(sell_ticket),
                  "",
                  "",
                  "",
                  "SellStop注文取消成功",
                  false
               );
            }

            data.SetOCOSellTicket(0);
            cancelled = true;
         }
      }

      if(cancelled)
      {
         Print("[ExecutionManager] CANCEL成功");
         data.SetExecResult(EXEC_RESULT_SUCCESS, "CANCEL成功", tick_id);
      }
      else
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "CANCEL失敗", tick_id);
      }

      return true;
   }

   //-------------------------------------------------------------------
   //| ポジション決済処理（Phase 3: 実装）                                |
   //-------------------------------------------------------------------
   bool HandleClose(CLA_Data &data, ulong tick_id)
   {
      // Phase 3では未実装（将来拡張用）
      Print("[ExecutionManager] CLOSE処理（未実装）");
      data.SetExecResult(EXEC_RESULT_SUCCESS, "CLOSE処理（未実装）", tick_id);
      return true;
   }


   //+------------------------------------------------------------------+
   //| Phase C-4.2: 約定検知イベントログ                                 |
   //+------------------------------------------------------------------+
   void DetectFill(int position_count)
   {
      Print("[Aegis-EVENT][FILL] ポジション発生検知 total_positions=", position_count);
      
      // 最新のポジション情報を出力
      for(int i = PositionsTotal() - 1; i >= 0 && i >= PositionsTotal() - 3; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double price = PositionGetDouble(POSITION_PRICE_OPEN);
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);
            datetime time = (datetime)PositionGetInteger(POSITION_TIME);
            
            string type_str = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
            
            Print("[Aegis-EVENT][FILL] position ticket=", ticket,
                  " type=", type_str,
                  " price=", price,
                  " sl=", sl,
                  " tp=", tp,
                  " time=", TimeToString(time, TIME_DATE|TIME_SECONDS));
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Phase C-4.2: 孤児注文（SL/TP無し）検出                            |
   //+------------------------------------------------------------------+
   void DetectOrphanOrders()
   {
      for(int i = 0; i < OrdersTotal(); i++)
      {
         ulong ticket = OrderGetTicket(i);
         if(ticket > 0)
         {
            double sl = OrderGetDouble(ORDER_SL);
            double tp = OrderGetDouble(ORDER_TP);
            
            if(sl == 0.0 || tp == 0.0)
            {
               ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
               double price = OrderGetDouble(ORDER_PRICE_OPEN);
               string comment = OrderGetString(ORDER_COMMENT);
               long magic = OrderGetInteger(ORDER_MAGIC);
               
               Print("[Aegis-EVENT][ORPHAN] 孤児注文検出 ticket=", ticket,
                     " type=", EnumToString(type),
                     " price=", price,
                     " sl=", sl,
                     " tp=", tp,
                     " magic=", magic,
                     " comment=", comment);
            }
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Phase C-4.2: 注文・ポジション最終スナップショット                  |
   //+------------------------------------------------------------------+
   void PrintPostSnapshot()
   {
      int orders_total = OrdersTotal();
      int positions_total = PositionsTotal();
      
      Print("[Aegis-EVENT][POST] orders_total=", orders_total,
            " positions_total=", positions_total);
      
      // 注文チケット一覧（最大5件）
      string pending_tickets = "";
      for(int i = 0; i < MathMin(orders_total, 5); i++)
      {
         ulong ticket = OrderGetTicket(i);
         if(ticket > 0)
         {
            if(i > 0) pending_tickets += ",";
            pending_tickets += IntegerToString(ticket);
         }
      }
      
      if(orders_total > 0)
      {
         Print("[Aegis-EVENT][POST] pending_tickets=[", pending_tickets, "]");
      }
      
      // ポジションチケット一覧（最大5件）
      string position_tickets = "";
      for(int i = 0; i < MathMin(positions_total, 5); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(i > 0) position_tickets += ",";
            position_tickets += IntegerToString(ticket);
         }
      }
      
      if(positions_total > 0)
      {
         Print("[Aegis-EVENT][POST] position_tickets=[", position_tickets, "]");
      }
   }
};
//+------------------------------------------------------------------+
