//+------------------------------------------------------------------+
//|                                               Aegis_Core.mqh     |
//|                                  Copyright 2025, Aegis Project   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Aegis Project"
#property link        "https://github.com/YasuharuEA/Aegis"
#property version     "1.30"  // ★Phase 2 骨格実装
#property strict

//+------------------------------------------------------------------+
//| ユーザーパラメータ                                                |
//+------------------------------------------------------------------+
input int    InpMagicNumber = 123456;
input double InpLots = 0.01;
input int    InpSlippage = 3;
input double InpSL = 0.0;
input double InpTP = 0.0;
input bool   InpEnableConsoleLog = false;

//+------------------------------------------------------------------+
//| インクルード                                                     |
//+------------------------------------------------------------------+
#include <CLA/00_Common/CLA_Common.mqh>
#include <CLA/00_Common/CLA_Data.mqh>
#include <CLA/01_Gatekeeper/CGatekeeper.mqh>
#include <CLA/02_Observation/CObservationPrice.mqh>
#include <CLA/02_Observation/CObservationRSI.mqh>
#include <CLA/03_Decision/CDecisionRSI_Simple.mqh>
#include <CLA/04_Execution/CExecutionBase.mqh>
#include <CLA/04_Execution/CExecutionManager.mqh>  // ★Phase 2追加

//+------------------------------------------------------------------+
//| グローバルインスタンス                                            |
//+------------------------------------------------------------------+
CGatekeeper           g_gatekeeper;
CObservationPrice     g_observer_price;
CObservationRSI       g_observer_rsi(14);
CDecisionRSI_Simple   g_decision_rsi(&g_observer_rsi, 30.0, 70.0);
CExecutionBase        g_execution(InpMagicNumber, InpSlippage);        // 既存（温存）
CExecutionManager     g_exec_manager(InpMagicNumber, InpSlippage);     // ★Phase 2追加

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int AegisInit()
{
   Print("[起動] Aegis Hybrid EA (Phase 2 骨格実装)");  // ★Phase 2表示
   
   // ========== CLA_Data初期化 ==========
   if(!g_data.Init())
   {
      Print("[エラー] CLA_Data初期化失敗");
      return INIT_FAILED;
   }
   
   g_data.SetConsoleLogEnabled(InpEnableConsoleLog);
   
   // ========== Gatekeeper初期化 ==========
   if(!g_gatekeeper.Init())
   {
      Print("[エラー] Gatekeeper初期化失敗");
      return INIT_FAILED;
   }
   
   // ========== 観測層初期化 ==========
   if(!g_observer_price.Init())
   {
      Print("[エラー] 価格観測初期化失敗");
      return INIT_FAILED;
   }
   
   if(!g_observer_rsi.Init())
   {
      Print("[エラー] RSI観測初期化失敗");
      return INIT_FAILED;
   }
   
   // ========== 判断層初期化 ==========
   if(!g_decision_rsi.Init())
   {
      Print("[エラー] RSI判断初期化失敗");
      return INIT_FAILED;
   }
   
   // ========== 実行層初期化（既存） ==========
   if(!g_execution.Init())
   {
      Print("[エラー] 実行層初期化失敗");
      return INIT_FAILED;
   }
   
   // ========== ExecutionManager初期化（Phase 2追加） ==========
   if(!g_exec_manager.Init())
   {
      Print("[エラー] ExecutionManager初期化失敗");
      return INIT_FAILED;
   }
   
   Print("[起動完了] Aegis Hybrid EA (Phase 2)");
   PrintFormat("[設定] コンソールログ: %s", InpEnableConsoleLog ? "表示(ON)" : "非表示(OFF)");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void AegisDeinit(const int reason)
{
   Print("[終了] Aegis Hybrid EA");
   
   g_exec_manager.Deinit();  // ★Phase 2追加
   g_execution.Deinit();
   g_decision_rsi.Deinit();
   g_observer_rsi.Deinit();
   g_observer_price.Deinit();
   g_gatekeeper.Deinit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void AegisTick()
{
   static ulong tick_id = 0;
   tick_id++;
   
   // ========================================
   // Layer 1: Gatekeeper チェック
   // ========================================
   ENUM_GK_RESULT gk_reason = GK_PASS;
   
   if(!g_gatekeeper.Execute(g_data, tick_id, gk_reason))
   {
      g_data.SetGatekeeperResult(gk_reason, tick_id);
      return;
   }
   
   // ========================================
   // Layer 2: 観測
   // ========================================
   g_observer_price.Update(g_data, tick_id);
   g_observer_rsi.Update(g_data, tick_id);
   
   // ========================================
   // Layer 3: 判断
   // ========================================
   g_decision_rsi.Update(g_data, tick_id);
   SignalData signal = g_decision_rsi.GetLastSignal();
   
   // ========================================
   // Layer 4: 実行（Phase 2 ダミーテスト）
   // ========================================
   
   // ★Phase 2追加: ダミー要求設定（10Tick毎にPLACE要求）
   if((tick_id % 10) == 0)
   {
      g_data.SetExecRequest(EXEC_REQ_PLACE, tick_id);
      Print("[テスト] ダミーPLACE要求を設定");
   }
   
   // ★Phase 2追加: ExecutionManager実行
   if(!g_exec_manager.Execute(g_data, tick_id))
   {
      // 致命的エラー → EA停止
      Print("[致命的エラー] ExecutionManager が false を返しました");
      Print("[緊急停止] 全ポジションクローズ → EA終了");
      
      // 全ポジションクローズ
      g_execution.CloseAll();
      
      // EA停止
      #ifdef __MQL5__
         ExpertRemove();
      #else
         Print("[MQL4] EAを手動で停止してください");
      #endif
      
      return;
   }
   
   // ========================================
   // 既存のエントリーロジック（温存）
   // ========================================
   if(signal.signal_type == SIGNAL_BUY)
   {
      if(g_execution.GetPositionCount() == 0)
      {
         g_execution.EntryBuy(InpLots, InpSL, InpTP);
      }
   }
   else if(signal.signal_type == SIGNAL_SELL)
   {
      if(g_execution.GetPositionCount() == 0)
      {
         g_execution.EntrySell(InpLots, InpSL, InpTP);
      }
   }
}