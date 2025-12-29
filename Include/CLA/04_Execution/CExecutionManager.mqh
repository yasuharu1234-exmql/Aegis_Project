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
      
      Print("[ExecutionManager] 骨格実装初期化完了");
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
      // ========== ロック解除（前Tickのロックをクリア） ==========
      if(data.IsExecLocked())
      {
         data.SetExecLock(false, tick_id);
      }
      
      // ========== 状態チェック ==========
      ENUM_EXEC_STATE current_state = data.GetExecState();
      
      // BLOCKED状態の場合
      if(current_state == EXEC_STATE_BLOCKED)
      {
         data.SetExecResult(EXEC_RESULT_REJECTED, 
                           "BLOCKED状態のため実行不可", 
                           tick_id);
         return true;
      }
      
      // 再入防止
      if(current_state == EXEC_STATE_IN_PROGRESS)
      {
         data.SetExecLock(true, tick_id);
         data.SetExecResult(EXEC_RESULT_REJECTED,
                           "処理中のため再入禁止",
                           tick_id);
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
            data.SetExecResult(EXEC_RESULT_INVALID_PARAMS,
                              "未知の操作要求",
                              tick_id);
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
         ENUM_EXEC_RESULT result = data.GetExecLastResult();
         
         if(result == EXEC_RESULT_FATAL_ERROR)
         {
            data.SetExecState(EXEC_STATE_BLOCKED, tick_id, "致命的エラー");
            Print("[ExecutionManager] ❌ 致命的エラー検出 - EA停止");
            return false;
         }
         else
         {
            data.SetExecState(EXEC_STATE_FAILED, tick_id, "処理失敗");
         }
      }
      
      // 要求クリア
      data.SetExecRequest(EXEC_REQ_NONE, tick_id);
      
      return true;
   }
   
private:
   //-------------------------------------------------------------------
   //| 新規注文処理（ダミー実装 - 分岐パターン追加）                      |
   //-------------------------------------------------------------------
   bool HandlePlace(CLA_Data &data, ulong tick_id)
   {
      Print("[ExecutionManager] 🔷 PLACE処理開始（ダミー）");
      
      // ========== ダミー分岐条件 ==========
      // Tick ID の末尾桁で結果を分岐
      int pattern = (int)(tick_id % 10);
      
      // ========================================
      // パターン1: 成功（APPLIED）
      // TickID末尾が 0, 2, 4, 6, 8 の場合
      // ========================================
      if(pattern == 0 || pattern == 2 || pattern == 4 || pattern == 6 || pattern == 8)
      {
         data.SetExecResult(EXEC_RESULT_SUCCESS, 
                           StringFormat("注文成功（ダミー）TickID=%llu", tick_id),
                           tick_id);
         Print("[ExecutionManager] ✅ PLACE成功パターン");
         return true;
      }
      
      // ========================================
      // パターン2: 非致命的失敗（FAILED）
      // TickID末尾が 1, 3, 7 の場合
      // ========================================
      else if(pattern == 1 || pattern == 3 || pattern == 7)
      {
         // リクオート（再試行可能）
         data.SetExecResult(EXEC_RESULT_REQUOTE,
                           StringFormat("リクオート発生（ダミー）TickID=%llu - Strategyは次Tickで再判断可能", tick_id),
                           tick_id);
         Print("[ExecutionManager] ⚠️ PLACE失敗（リクオート） - 非致命的");
         return false; // 失敗だが再試行可能
      }
      
      // ========================================
      // パターン3: ブロック状態（実行抑止）
      // TickID末尾が 5 の場合
      // ========================================
      else if(pattern == 5)
      {
         // スプレッド異常などの物理条件NG
         data.SetExecResult(EXEC_RESULT_REJECTED,
                           StringFormat("物理条件NG（ダミー）TickID=%llu - スプレッド異常を想定", tick_id),
                           tick_id);
         Print("[ExecutionManager] 🚫 PLACE失敗（物理条件NG） - BLOCKED相当");
         return false;
      }
      
      // ========================================
      // パターン4: その他（念のため）
      // TickID末尾が 9 の場合
      // ========================================
      else
      {
         data.SetExecResult(EXEC_RESULT_REJECTED,
                           StringFormat("その他エラー（ダミー）TickID=%llu", tick_id),
                           tick_id);
         Print("[ExecutionManager] ⚠️ PLACE失敗（その他）");
         return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 注文修正処理（ダミー実装）                                         |
   //-------------------------------------------------------------------
   bool HandleModify(CLA_Data &data, ulong tick_id)
   {
      Print("[ExecutionManager] 🔷 MODIFY処理（ダミー）");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 注文取消処理（ダミー実装）                                         |
   //-------------------------------------------------------------------
   bool HandleCancel(CLA_Data &data, ulong tick_id)
   {
      Print("[ExecutionManager] 🔷 CANCEL処理（ダミー）");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| ポジション決済処理（ダミー実装）                                   |
   //-------------------------------------------------------------------
   bool HandleClose(CLA_Data &data, ulong tick_id)
   {
      Print("[ExecutionManager] 🔷 CLOSE処理（ダミー）");
      return true;
   }
};
