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
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CExecutionManager(int magic_number, int slippage = 3) 
      : CExecutionBase(magic_number, slippage)
   {
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
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};
         
         request.action = TRADE_ACTION_REMOVE;
         request.order  = buy_ticket;
         
         if(!exMQL.OrderSend(request, result))
         {
            int error_code = GetLastError();
            Print("[ExecutionManager] BuyStop CANCEL失敗: ", error_code);
         }
         else
         {
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
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};
         
         request.action = TRADE_ACTION_REMOVE;
         request.order  = sell_ticket;
         
         if(!exMQL.OrderSend(request, result))
         {
            int error_code = GetLastError();
            Print("[ExecutionManager] SellStop CANCEL失敗: ", error_code);
         }
         else
         {
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
};
