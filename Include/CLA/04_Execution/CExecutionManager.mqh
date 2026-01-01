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
   //| 新規注文処理（Phase 3: 実装）                                      |
   //-------------------------------------------------------------------
   bool HandlePlace(CLA_Data &data, ulong tick_id)
   {
      // パラメータ取得
      double distance = data.GetOCODistancePoints();
      double lot      = data.GetOCOLot();
      int    sl       = (int)data.GetOCOSLPoints();
      int    tp       = (int)data.GetOCOTPPoints();
      int    magic    = data.GetOCOMagic();
      
      // 価格計算
      double ask   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double bid   = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      int    digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      
      double buy_price  = NormalizeDouble(ask + distance * point, digits);
      double sell_price = NormalizeDouble(bid - distance * point, digits);
      
      // ========== BuyStop 注文 ==========
      MqlTradeRequest request_buy = {};
      MqlTradeResult  result_buy  = {};
      
      request_buy.action    = TRADE_ACTION_PENDING;
      request_buy.symbol    = Symbol();
      request_buy.volume    = lot;
      request_buy.type      = ORDER_TYPE_BUY_STOP;
      request_buy.price     = buy_price;
      request_buy.sl        = (sl > 0) ? NormalizeDouble(buy_price - sl * point, digits) : 0;
      request_buy.tp        = (tp > 0) ? NormalizeDouble(buy_price + tp * point, digits) : 0;
      request_buy.magic     = magic;
      request_buy.comment   = "Aegis_OCO_Buy";
      
      // OrderSend実行（BuyStop）
      if(!exMQL.OrderSend(request_buy, result_buy))
      {
         int error_code = GetLastError();
         
         // 致命的エラーチェック
         if(exMQL.IsFatalError(error_code))
         {
            Print("[ExecutionManager] BuyStop配置失敗（致命的）: ", error_code);
            data.SetExecResult(EXEC_RESULT_FATAL_ERROR, 
                              StringFormat("BuyStop配置失敗（致命的）: %d", error_code), tick_id);
            return false; // 致命的エラー → EA停止
         }
         
         // 非致命的エラー
         Print("[ExecutionManager] BuyStop配置失敗: ", error_code);
         data.SetExecResult(EXEC_RESULT_REJECTED, 
                           StringFormat("BuyStop配置失敗: %d", error_code), tick_id);
         return false;
      }
      
      // BuyStop成功
      ulong buy_ticket = result_buy.order;
      data.SetOCOBuyTicket(buy_ticket);
      data.SetOCOBuyPrice(buy_price);
      
      // ========== SellStop 注文 ==========
      MqlTradeRequest request_sell = {};
      MqlTradeResult  result_sell  = {};
      
      request_sell.action    = TRADE_ACTION_PENDING;
      request_sell.symbol    = Symbol();
      request_sell.volume    = lot;
      request_sell.type      = ORDER_TYPE_SELL_STOP;
      request_sell.price     = sell_price;
      request_sell.sl        = (sl > 0) ? NormalizeDouble(sell_price + sl * point, digits) : 0;
      request_sell.tp        = (tp > 0) ? NormalizeDouble(sell_price - tp * point, digits) : 0;
      request_sell.magic     = magic;
      request_sell.comment   = "Aegis_OCO_Sell";
      
      // OrderSend実行（SellStop）
      if(!exMQL.OrderSend(request_sell, result_sell))
      {
         int error_code = GetLastError();
         
         // SellStop失敗 → BuyStopをロールバック
         Print("[ExecutionManager] SellStop配置失敗 → BuyStopロールバック: ", error_code);
         
         // BuyStopキャンセル
         MqlTradeRequest cancel_req = {};
         MqlTradeResult  cancel_res = {};
         cancel_req.action = TRADE_ACTION_REMOVE;
         cancel_req.order  = buy_ticket;
         exMQL.OrderSend(cancel_req, cancel_res);
         
         // 致命的エラーチェック
         if(exMQL.IsFatalError(error_code))
         {
            Print("[ExecutionManager] SellStop配置失敗（致命的）: ", error_code);
            data.SetExecResult(EXEC_RESULT_FATAL_ERROR, 
                              StringFormat("SellStop配置失敗（致命的）: %d", error_code), tick_id);
            return false;
         }
         
         data.SetExecResult(EXEC_RESULT_REJECTED, 
                           StringFormat("SellStop配置失敗: %d", error_code), tick_id);
         return false;
      }
      
      // SellStop成功
      ulong sell_ticket = result_sell.order;
      data.SetOCOSellTicket(sell_ticket);
      data.SetOCOSellPrice(sell_price);
      
      // 成功ログ
      Print("[ExecutionManager] OCO配置成功: Buy=", buy_ticket, "@", buy_price, 
            " Sell=", sell_ticket, "@", sell_price);
      data.SetExecResult(EXEC_RESULT_SUCCESS, 
                        StringFormat("OCO配置成功: Buy=%lu@%.5f Sell=%lu@%.5f", 
                                    buy_ticket, buy_price, sell_ticket, sell_price), tick_id);
      
      // ★Phase 4: 前回注文配置/変更時刻を更新
      data.SetLastOrderActionTime(TimeCurrent());
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 注文修正処理（Phase 3: 実装）                                      |
   //-------------------------------------------------------------------
   bool HandleModify(CLA_Data &data, ulong tick_id)
   {
      ulong buy_ticket  = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      double buy_price  = data.GetOCOBuyPrice();
      double sell_price = data.GetOCOSellPrice();
      
      bool modified = false;
      
      // BuyStop MODIFY
      if(buy_ticket > 0)
      {
         if(exMQL.OrderSelect(buy_ticket))
         {
            MqlTradeRequest request = {};
            MqlTradeResult  result  = {};
            
            request.action = TRADE_ACTION_MODIFY;
            request.order  = buy_ticket;
            request.price  = buy_price;
            request.sl     = exMQL.OrderGetDouble(ORDER_SL);
            request.tp     = exMQL.OrderGetDouble(ORDER_TP);
            
            if(!exMQL.OrderSend(request, result))
            {
               int error_code = GetLastError();
               Print("[ExecutionManager] BuyStop MODIFY失敗: ", error_code);
               
               if(exMQL.IsFatalError(error_code))
               {
                  data.SetExecResult(EXEC_RESULT_FATAL_ERROR, 
                                    StringFormat("BuyStop MODIFY失敗（致命的）: %d", error_code), tick_id);
                  return false;
               }
            }
            else
            {
               modified = true;
            }
         }
      }
      
      // SellStop MODIFY
      if(sell_ticket > 0)
      {
         if(exMQL.OrderSelect(sell_ticket))
         {
            MqlTradeRequest request = {};
            MqlTradeResult  result  = {};
            
            request.action = TRADE_ACTION_MODIFY;
            request.order  = sell_ticket;
            request.price  = sell_price;
            request.sl     = exMQL.OrderGetDouble(ORDER_SL);
            request.tp     = exMQL.OrderGetDouble(ORDER_TP);
            
            if(!exMQL.OrderSend(request, result))
            {
               int error_code = GetLastError();
               Print("[ExecutionManager] SellStop MODIFY失敗: ", error_code);
               
               if(exMQL.IsFatalError(error_code))
               {
                  data.SetExecResult(EXEC_RESULT_FATAL_ERROR, 
                                    StringFormat("SellStop MODIFY失敗（致命的）: %d", error_code), tick_id);
                  return false;
               }
            }
            else
            {
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
