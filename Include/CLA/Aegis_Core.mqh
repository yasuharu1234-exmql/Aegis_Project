//+------------------------------------------------------------------+
//| File    : Aegis_Core.mqh                                         |
//| Project : Aegis Hybrid EA                                       |
//|                                                                  |
//| Role                                                             |
//|  - Aegis 全体の制御フローを統括する中枢                          |
//|  - 各レイヤーの呼び出し順序と責務境界を保証する                  |
//|                                                                  |
//| Execution Order                                                  |
//|  1. Gatekeeper   : 実行可否の事前チェック                        |
//|  2. Observation  : 市場データの観測                              |
//|  3. Decision     : 売買判断                                      |
//|  4. Execution    : 注文実行                                      |
//|                                                                  |
//| Design Philosophy                                                |
//|  - 各レイヤーは互いに直接干渉しない                              |
//|  - データ共有は CLA_Data のみを通して行う                        |
//|  - ロジックは薄く、流れは明確に                                 |
//|                                                                  |
//| Phase 2 Notes                                                    |
//|  - Strategy ⇔ Execution の接続確認フェーズ                       |
//|  - ダミー実行コードは排除済み                                    |
//|                                                                  |
//| Change Policy                                                    |
//|  - 処理順序の変更は慎重に行う                                    |
//|  - レイヤー統合は禁止                                           |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property link        "https://github.com/YasuharuEA/Aegis"
#property version     "1.30"  // ★Phase 2 骨格実装
#property strict

//+------------------------------------------------------------------+
//| ユーザーパラメータ（Phase 2: 外部パラメータ化）                   |
//+------------------------------------------------------------------+

// ========== OCO配置設定 ==========
input int    InpOCODistancePoints  = 50;      // OCO注文の価格間隔（ポイント）
input double InpOCOLotSize         = 0.1;     // OCO注文のロットサイズ
input int    InpOCOSLPoints        = 100;     // ストップロス（ポイント）
input int    InpOCOTPPoints        = 200;     // テイクプロフィット（ポイント）

// ========== 追従設定 ==========
input int    InpTrailTriggerPoints      = 10;   // 追従開始トリガー（ポイント）
input int    InpTrailIntervalSec        = 0;    // 追従判定間隔（秒、0=毎Tick）
input int    InpMaxSpreadPoints         = 30;   // 最大許容スプレッド（ポイント）
input int    InpSpreadWideIntervalSec   = 60;   // スプレッド拡大時の待機時間（秒）
input bool   InpUseIntervalOHLC         = true; // 間隔モード時にOHLCを使用
input int    InpMaxTrailCount           = 0;    // 最大追従回数（0=無制限）

// ========== ログ設定 ==========
input int    InpMaxLogRecords      = 2048;    // ログ最大記録件数
input bool   InpEnableConsoleLog   = true;    // コンソールログ出力

// ========== リスク管理 ==========
input int    InpMaxPositions       = 1;       // 同時保有最大ポジション数
input int    InpMagicNumber        = 20250101; // マジックナンバー

// ========== 旧パラメータ（互換性のため残す） ==========
input double InpLots = 0.01;
input int    InpSlippage = 3;
input double InpSL = 0.0;
input double InpTP = 0.0;

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
#include <CLA/05_Strategy/CStrategy_OCOFollow.mqh> // ★Sprint D追加
#include <CLA/05_Strategy/CStrategyManager.mqh>     // ★Sprint E追加

//+------------------------------------------------------------------+
//| グローバルインスタンス                                            |
//+------------------------------------------------------------------+
CGatekeeper           g_gatekeeper;
CObservationPrice     g_observer_price;
CObservationRSI       g_observer_rsi;  // パラメータなし
CDecisionRSI_Simple   g_decision_rsi(&g_observer_rsi, 30.0, 70.0);
CExecutionBase        g_execution(InpMagicNumber, InpSlippage);        // 既存（温存）
CStrategy_OCOFollow   g_strategy_oco;  // ★Phase 2: パラメータなし（Init()で設定）
CStrategyManager      g_strategy_manager;                                // ★Sprint E追加
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
   
   // ========== OCO戦略初期化（Phase 2: パラメータ付き） ==========
   if(!g_strategy_oco.Init(
      InpOCODistancePoints,
      InpOCOLotSize,
      InpOCOSLPoints,
      InpOCOTPPoints,
      InpTrailTriggerPoints,
      InpTrailIntervalSec,
      InpMaxSpreadPoints,
      InpSpreadWideIntervalSec,
      InpUseIntervalOHLC,
      InpMaxTrailCount,
      InpMagicNumber
   ))
   {
      Print("[エラー] OCO戦略初期化失敗");
      return INIT_FAILED;
   }
   
   // ========== StrategyManager初期化（Sprint E追加） ==========
   g_strategy_manager.Init(g_strategy_oco);
   
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
   
   g_strategy_oco.Deinit();  // ★Sprint D追加
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
   
   // ★Phase 5: デバッグログ（最初の10 Tickのみ）
   if(tick_id <= 10)
   {
      Print("[DEBUG] Tick#", tick_id, " 開始");
   }
   
   // ========================================
   // Layer 1: Gatekeeper チェック
   // ========================================
   ENUM_GK_RESULT gk_reason = GK_PASS;
   
   if(!g_gatekeeper.Execute(g_data, tick_id, gk_reason))
   {
      g_data.SetGatekeeperResult(gk_reason, tick_id);
      
      // ★Phase 5: Gatekeeper遮断時のデバッグログ（最初の10 Tickのみ）
      if(tick_id <= 10)
      {
         Print("[DEBUG] Tick#", tick_id, " Gatekeeper遮断: ", EnumToString(gk_reason));
      }
      
      return;
   }
   
   // ★Phase 5: デバッグログ（最初の10 Tickのみ）
   if(tick_id <= 10)
   {
      Print("[DEBUG] Tick#", tick_id, " Gatekeeper通過");
   }
   
   // ========================================
   // Layer 2: 観測
   // ========================================
   g_observer_price.Update(g_data, tick_id);
   g_observer_rsi.Update(g_data, tick_id);
   
   // ========================================
   // Layer 3: 判断
   // ========================================
   // g_decision_rsi.Update(g_data, tick_id);  // ★Sprint D: RSI戦略は一旦無効化
   // SignalData signal = g_decision_rsi.GetLastSignal();
   
   // ★Sprint E追加: StrategyManager経由で実行
   g_strategy_manager.Update(g_data, tick_id);
   
   // ★Phase 5: デバッグログ（最初の10 Tickのみ）
   if(tick_id <= 10)
   {
      Print("[DEBUG] Tick#", tick_id, " Strategy完了");
   }
   
   // ========================================
   // Layer 4: 実行
   // ========================================
   
   // ★Sprint D追加: ExecutionManager実行
   
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
   
   // ★Phase 5: デバッグログ（最初の10 Tickのみ）
   if(tick_id <= 10)
   {
      Print("[DEBUG] Tick#", tick_id, " 完了");
   }
   
   // ========================================
   // 既存のエントリーロジック（Sprint D: 無効化）
   // ========================================
   // ★Sprint D: OCO戦略を使用するため、RSI連動ロジックは無効化
   /*
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
   */
}