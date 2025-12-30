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
   //| 新規注文処理（ダミー実装）                                         |
   //-------------------------------------------------------------------
   bool HandlePlace(CLA_Data &data, ulong tick_id)
   {
      // ========== ダミー分岐条件 ==========
      // Tick ID の末尾桁で結果を分岐
      int pattern = (int)(tick_id % 10);
      
      // パターン1: 成功（偶数）
      if(pattern % 2 == 0)
      {
         data.SetExecResult(EXEC_RESULT_SUCCESS, 
                           StringFormat("注文成功（ダミー）TickID=%llu", tick_id), tick_id);
         return true;
      }
      // パターン2: 失敗（奇数）
      else
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, 
                           StringFormat("注文失敗（ダミー）TickID=%llu", tick_id), tick_id);
         return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 注文修正処理（ダミー実装）                                         |
   //-------------------------------------------------------------------
   bool HandleModify(CLA_Data &data, ulong tick_id)
   {
      data.SetExecResult(EXEC_RESULT_SUCCESS, "MODIFY処理（ダミー）", tick_id);
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 注文取消処理（ダミー実装）                                         |
   //-------------------------------------------------------------------
   bool HandleCancel(CLA_Data &data, ulong tick_id)
   {
      data.SetExecResult(EXEC_RESULT_SUCCESS, "CANCEL処理（ダミー）", tick_id);
      return true;
   }
   
   //-------------------------------------------------------------------
   //| ポジション決済処理（ダミー実装）                                   |
   //-------------------------------------------------------------------
   bool HandleClose(CLA_Data &data, ulong tick_id)
   {
      data.SetExecResult(EXEC_RESULT_SUCCESS, "CLOSE処理（ダミー）", tick_id);
      return true;
   }
};
