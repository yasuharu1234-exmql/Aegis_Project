//+------------------------------------------------------------------+
//| File    : CExecutionManager.mqh                                  |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Execution                                              |
//|                                                                  |
//| Role                                                             |
//|  - Strategy層から渡された実行要求を処理する                      |
//|  - OrderSend / Modify / Close 等の「実行のみ」を担当             |
//|                                                                  |
//| Core Principle                                                   |
//|  - 判断しない                                                    |
//|  - 例外を握りつぶさない                                          |
//|  - 結果と理由を Context（CLA_Data）に正確に記録する              |
//|                                                                  |
//| Design Policy                                                    |
//|  - 戻り値 bool は「EAを即死させるべきか」のみを表す               |
//|  - 成功／失敗の詳細は必ず CLA_Data に書き込む                    |
//|  - Strategy層の意図を勝手に補完・修正しない                      |
//|                                                                  |
//| Phase 2 Notes                                                    |
//|  - PLACE / MODIFY / CANCEL / CLOSE を段階的に実装予定            |
//|  - REPLACE は CANCEL + PLACE に分解して扱う                      |
//|  - Task #5 で確定した API のみ使用                               |
//|                                                                  |
//| Change Policy                                                    |
//|  - 実装拡張は可                                                  |
//|  - 判断ロジックの追加は禁止                                      |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CExecutionBase.mqh"

//+------------------------------------------------------------------+
//| Class   : CExecutionManager                                      |
//| Layer   : Execution                                              |
//|                                                                  |
//| Responsibility                                                  |
//|  - 実行要求のディスパッチ                                        |
//|  - 実行状態の遷移管理（IDLE / IN_PROGRESS / APPLIED / FAILED）  |
//|                                                                  |
//| Important                                                        |
//|  - このクラスは「安全装置付きの引き金」である                    |
//|  - 引くかどうかを決めるのは Strategy 層                          |
//|                                                                  |
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
      
      Print("[ExecutionManager] Phase 2 骨格実装初期化完了");
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
   //| [戻り値]                                                          |
   //|   true  : 継続可能                                               |
   //|   false : EA停止必要（致命的エラー）                              |
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
      
      // ========== 操作要求のハンドリング（ダミー実装） ==========
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
         data.SetExecResult(EXEC_RESULT_SUCCESS, "正常完了", tick_id);
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
   //-------------------------------------------------------------------
   //| 新規注文処理（OCO: BuyStop + SellStop）                           |
   //-------------------------------------------------------------------
   bool HandlePlace(CLA_Data &data, ulong tick_id)
   {
      // ========== OCOパラメータ取得 ==========
      double lot = data.GetOCOLot();
      double distance_points = data.GetOCODistancePoints();
      double sl_points = data.GetOCOSLPoints();
      double tp_points = data.GetOCOTPPoints();
      int magic = data.GetOCOMagic();
      
      // ========== 現在価格取得 ==========
      double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      if(ask <= 0 || bid <= 0 || point <= 0)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "価格情報取得失敗", tick_id);
         Print("❌ [HandlePlace] 価格情報取得失敗");
         return false;
      }
      
      // ========== OCO価格計算 ==========
      double buy_price = ask + (distance_points * point);
      double sell_price = bid - (distance_points * point);
      
      // 価格を正規化
      int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      buy_price = NormalizeDouble(buy_price, digits);
      sell_price = NormalizeDouble(sell_price, digits);
      
      // ========== BuyStop 発注 ==========
      MqlTradeRequest request_buy = {};
      MqlTradeResult result_buy = {};
      
      request_buy.action = TRADE_ACTION_PENDING;
      request_buy.symbol = Symbol();
      request_buy.volume = lot;
      request_buy.type = ORDER_TYPE_BUY_STOP;
      request_buy.price = buy_price;
      request_buy.sl = (sl_points > 0) ? buy_price - (sl_points * point) : 0;
      request_buy.tp = (tp_points > 0) ? buy_price + (tp_points * point) : 0;
      request_buy.deviation = m_slippage;
      request_buy.magic = magic;
      request_buy.comment = "Aegis_OCO_Buy";
      
      if(!OrderSend(request_buy, result_buy))
      {
         string error_msg = StringFormat("BuyStop発注失敗: エラーコード=%d, %s", 
                                        GetLastError(), result_buy.comment);
         data.SetExecResult(EXEC_RESULT_REJECTED, error_msg, tick_id);
         Print("❌ [HandlePlace] ", error_msg);
         return false;
      }
      
      if(result_buy.retcode != TRADE_RETCODE_DONE && result_buy.retcode != TRADE_RETCODE_PLACED)
      {
         string error_msg = StringFormat("BuyStop配置失敗: retcode=%d, %s", 
                                        result_buy.retcode, result_buy.comment);
         data.SetExecResult(EXEC_RESULT_REJECTED, error_msg, tick_id);
         Print("❌ [HandlePlace] ", error_msg);
         return false;
      }
      
      Print("✅ [HandlePlace] BuyStop発注成功: チケット=", result_buy.order, 
            " 価格=", buy_price);
      
      // ========== SellStop 発注 ==========
      MqlTradeRequest request_sell = {};
      MqlTradeResult result_sell = {};
      
      request_sell.action = TRADE_ACTION_PENDING;
      request_sell.symbol = Symbol();
      request_sell.volume = lot;
      request_sell.type = ORDER_TYPE_SELL_STOP;
      request_sell.price = sell_price;
      request_sell.sl = (sl_points > 0) ? sell_price + (sl_points * point) : 0;
      request_sell.tp = (tp_points > 0) ? sell_price - (tp_points * point) : 0;
      request_sell.deviation = m_slippage;
      request_sell.magic = magic;
      request_sell.comment = "Aegis_OCO_Sell";
      
      if(!OrderSend(request_sell, result_sell))
      {
         string error_msg = StringFormat("SellStop発注失敗: エラーコード=%d, %s", 
                                        GetLastError(), result_sell.comment);
         // BuyStopをキャンセル（ロールバック）
         MqlTradeRequest cancel_req = {};
         MqlTradeResult cancel_res = {};
         cancel_req.action = TRADE_ACTION_REMOVE;
         cancel_req.order = result_buy.order;
         
         if(!OrderSend(cancel_req, cancel_res))
         {
            int cancel_error = GetLastError();
            Print("⚠️ [HandlePlace] BuyStopキャンセル失敗: エラー=", cancel_error);
         }
         else if(cancel_res.retcode != TRADE_RETCODE_DONE)
         {
            Print("⚠️ [HandlePlace] BuyStopキャンセル失敗: retcode=", cancel_res.retcode);
         }
         else
         {
            Print("✅ [HandlePlace] BuyStop#", result_buy.order, " ロールバック成功");
         }
         
         data.SetExecResult(EXEC_RESULT_REJECTED, error_msg, tick_id);
         Print("❌ [HandlePlace] ", error_msg);
         return false;
      }
      
      if(result_sell.retcode != TRADE_RETCODE_DONE && result_sell.retcode != TRADE_RETCODE_PLACED)
      {
         string error_msg = StringFormat("SellStop配置失敗: retcode=%d, %s", 
                                        result_sell.retcode, result_sell.comment);
         // BuyStopをキャンセル（ロールバック）
         MqlTradeRequest cancel_req = {};
         MqlTradeResult cancel_res = {};
         cancel_req.action = TRADE_ACTION_REMOVE;
         cancel_req.order = result_buy.order;
         
         if(!OrderSend(cancel_req, cancel_res))
         {
            int cancel_error = GetLastError();
            Print("⚠️ [HandlePlace] BuyStopキャンセル失敗: エラー=", cancel_error);
         }
         else if(cancel_res.retcode != TRADE_RETCODE_DONE)
         {
            Print("⚠️ [HandlePlace] BuyStopキャンセル失敗: retcode=", cancel_res.retcode);
         }
         else
         {
            Print("✅ [HandlePlace] BuyStop#", result_buy.order, " ロールバック成功");
         }
         
         data.SetExecResult(EXEC_RESULT_REJECTED, error_msg, tick_id);
         Print("❌ [HandlePlace] ", error_msg);
         return false;
      }
      
      Print("✅ [HandlePlace] SellStop発注成功: チケット=", result_sell.order, 
            " 価格=", sell_price);
      
      // ========== 成功: CLA_Dataに保存 ==========
      data.SetOCOBuyTicket(result_buy.order);
      data.SetOCOSellTicket(result_sell.order);
      data.SetOCOBuyPrice(buy_price);
      data.SetOCOSellPrice(sell_price);
      
      string success_msg = StringFormat("OCO配置成功: Buy#%llu@%.5f / Sell#%llu@%.5f",
                                       result_buy.order, buy_price,
                                       result_sell.order, sell_price);
      data.SetExecResult(EXEC_RESULT_SUCCESS, success_msg, tick_id);
      Print("✅ [HandlePlace] ", success_msg);
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 注文修正処理（OCO価格更新）                                        |
   //-------------------------------------------------------------------
   bool HandleModify(CLA_Data &data, ulong tick_id)
   {
      // ========== OCOチケット・価格取得 ==========
      ulong buy_ticket  = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      double new_buy_price  = data.GetOCOBuyPrice();
      double new_sell_price = data.GetOCOSellPrice();
      
      if(buy_ticket == 0 && sell_ticket == 0)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "MODIFY対象の注文なし", tick_id);
         Print("⚠️ [HandleModify] MODIFY対象なし");
         return false;
      }
      
      bool modified = false;
      int modify_count = 0;
      
      // ========== BuyStop MODIFY ==========
      if(buy_ticket > 0)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};
         
         request.action = TRADE_ACTION_MODIFY;
         request.order = buy_ticket;
         request.price = new_buy_price;
         
         if(!OrderSend(request, result))
         {
            int error_code = GetLastError();
            Print("❌ [HandleModify] BuyStop#", buy_ticket, " MODIFY失敗: エラー=", error_code);
         }
         else if(result.retcode == TRADE_RETCODE_DONE)
         {
            Print("✅ [HandleModify] BuyStop#", buy_ticket, " MODIFY成功: 新価格=", new_buy_price);
            modified = true;
            modify_count++;
         }
         else
         {
            Print("❌ [HandleModify] BuyStop#", buy_ticket, " MODIFY失敗: retcode=", result.retcode);
         }
      }
      
      // ========== SellStop MODIFY ==========
      if(sell_ticket > 0)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};
         
         request.action = TRADE_ACTION_MODIFY;
         request.order = sell_ticket;
         request.price = new_sell_price;
         
         if(!OrderSend(request, result))
         {
            int error_code = GetLastError();
            Print("❌ [HandleModify] SellStop#", sell_ticket, " MODIFY失敗: エラー=", error_code);
         }
         else if(result.retcode == TRADE_RETCODE_DONE)
         {
            Print("✅ [HandleModify] SellStop#", sell_ticket, " MODIFY成功: 新価格=", new_sell_price);
            modified = true;
            modify_count++;
         }
         else
         {
            Print("❌ [HandleModify] SellStop#", sell_ticket, " MODIFY失敗: retcode=", result.retcode);
         }
      }
      
      // ========== 結果記録 ==========
      if(modified)
      {
         string msg = StringFormat("OCO追従更新成功: %d件", modify_count);
         data.SetExecResult(EXEC_RESULT_SUCCESS, msg, tick_id);
         Print("✅ [HandleModify] ", msg);
         return true;
      }
      else
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "追従更新失敗", tick_id);
         Print("❌ [HandleModify] 追従更新失敗");
         return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 注文取消処理（反対側注文のキャンセル）                             |
   //-------------------------------------------------------------------
   bool HandleCancel(CLA_Data &data, ulong tick_id)
   {
      // ========== キャンセル対象の判定 ==========
      ulong buy_ticket = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      
      if(buy_ticket == 0 && sell_ticket == 0)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "キャンセル対象の注文なし", tick_id);
         Print("⚠️ [HandleCancel] キャンセル対象なし");
         return false;
      }
      
      bool success = true;
      int cancel_count = 0;
      
      // ========== BuyStop キャンセル ==========
      if(buy_ticket > 0)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};
         
         request.action = TRADE_ACTION_REMOVE;
         request.order = buy_ticket;
         
         if(OrderSend(request, result))
         {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
               Print("✅ [HandleCancel] BuyStop#", buy_ticket, " キャンセル成功");
               data.SetOCOBuyTicket(0);
               cancel_count++;
            }
            else
            {
               Print("❌ [HandleCancel] BuyStop#", buy_ticket, " キャンセル失敗: retcode=", result.retcode);
               success = false;
            }
         }
         else
         {
            Print("❌ [HandleCancel] BuyStop#", buy_ticket, " OrderSend失敗: エラー=", GetLastError());
            success = false;
         }
      }
      
      // ========== SellStop キャンセル ==========
      if(sell_ticket > 0)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};
         
         request.action = TRADE_ACTION_REMOVE;
         request.order = sell_ticket;
         
         if(OrderSend(request, result))
         {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
               Print("✅ [HandleCancel] SellStop#", sell_ticket, " キャンセル成功");
               data.SetOCOSellTicket(0);
               cancel_count++;
            }
            else
            {
               Print("❌ [HandleCancel] SellStop#", sell_ticket, " キャンセル失敗: retcode=", result.retcode);
               success = false;
            }
         }
         else
         {
            Print("❌ [HandleCancel] SellStop#", sell_ticket, " OrderSend失敗: エラー=", GetLastError());
            success = false;
         }
      }
      
      // ========== 結果記録 ==========
      if(success && cancel_count > 0)
      {
         string msg = StringFormat("注文キャンセル成功: %d件", cancel_count);
         data.SetExecResult(EXEC_RESULT_SUCCESS, msg, tick_id);
         Print("✅ [HandleCancel] ", msg);
         return true;
      }
      else
      {
         string msg = StringFormat("注文キャンセル失敗: 成功%d件", cancel_count);
         data.SetExecResult(EXEC_RESULT_REJECTED, msg, tick_id);
         Print("❌ [HandleCancel] ", msg);
         return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| ポジション決済処理                                                 |
   //-------------------------------------------------------------------
   bool HandleClose(CLA_Data &data, ulong tick_id)
   {
      // ========== 現在のポジション検索 ==========
      int magic = data.GetOCOMagic();
      int total = PositionsTotal();
      bool found = false;
      ulong position_ticket = 0;
      
      for(int i = 0; i < total; i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         
         if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
         if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
         
         position_ticket = ticket;
         found = true;
         break;
      }
      
      if(!found)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, "決済対象のポジションなし", tick_id);
         Print("⚠️ [HandleClose] 決済対象なし");
         return false;
      }
      
      // ========== ポジション決済 ==========
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      
      request.action = TRADE_ACTION_DEAL;
      request.position = position_ticket;
      request.symbol = Symbol();
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.deviation = m_slippage;
      request.magic = magic;
      request.comment = "Aegis_Close";
      
      // 決済方向の判定
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(pos_type == POSITION_TYPE_BUY)
      {
         request.type = ORDER_TYPE_SELL;
         request.price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      }
      else
      {
         request.type = ORDER_TYPE_BUY;
         request.price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      }
      
      if(!OrderSend(request, result))
      {
         string error_msg = StringFormat("決済失敗: エラーコード=%d, %s", 
                                        GetLastError(), result.comment);
         data.SetExecResult(EXEC_RESULT_REJECTED, error_msg, tick_id);
         Print("❌ [HandleClose] ", error_msg);
         return false;
      }
      
      if(result.retcode != TRADE_RETCODE_DONE)
      {
         string error_msg = StringFormat("決済失敗: retcode=%d, %s", 
                                        result.retcode, result.comment);
         data.SetExecResult(EXEC_RESULT_REJECTED, error_msg, tick_id);
         Print("❌ [HandleClose] ", error_msg);
         return false;
      }
      
      string success_msg = StringFormat("ポジション決済成功: #%llu", position_ticket);
      data.SetExecResult(EXEC_RESULT_SUCCESS, success_msg, tick_id);
      Print("✅ [HandleClose] ", success_msg);
      
      return true;
   }
};
