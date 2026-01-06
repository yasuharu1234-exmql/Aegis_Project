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
//| フェーズF/G/H統合版                                              |
//|  - Decision層完全実装                                            |
//|  - RSI関連削除                                                   |
//|  - MQL5専用                                                      |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property link        "https://github.com/YasuharuEA/Aegis"
#property version     "2.00"  // ★フェーズF/G/H統合

//+------------------------------------------------------------------+
//| ユーザーパラメータ                                                |
//+------------------------------------------------------------------+

// ========== OCO配置設定 ==========
input int    InpOCODistancePoints  = 50;      // OCO注文の価格間隔（ポイント）
input double InpOCOLotSize         = 0.1;     // OCO注文のロットサイズ
input int    InpOCOSLPoints        = 100;     // ストップロス（ポイント）
input int    InpOCOTPPoints        = 200;     // テイクプロフィット（ポイント）

// ========== 追従設定 ==========
input int    InpTrailTriggerPoints      = 100;   // 追従開始トリガー（ポイント）
input int    InpTrailIntervalSec        = 30;    // 追従判定間隔（秒、0=毎Tick）
input int    InpMaxSpreadPoints         = 150;   // 最大許容スプレッド（ポイント）
input int    InpSpreadWideIntervalSec   = 60;   // スプレッド拡大時の待機時間（秒）
input bool   InpUseIntervalOHLC         = true; // 間隔モード時にOHLCを使用
input int    InpMaxTrailCount           = 10;    // 最大追従回数（0=無制限）

// ========== ログ設定 ==========
input int    InpMaxLogRecords      = 2048;    // ログ最大記録件数
input bool   InpEnableConsoleLog   = true;    // コンソールログ出力

// ========== 状態ログ設定 ==========
input bool   InpEnableStateLog     = true;    // 通常状態ログ有効/無効
input int    InpNoChangeLogDelta   = 5;       // 価格差分無視閾値（0.5pips）
input int    InpSpreadLogDelta     = 10;      // スプレッド変化量ログ閾値（1.0pips）

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
#include <CLA/02_Observation/CObservationOCOState.mqh>  // ★フェーズF追加
#include <CLA/03_Decision/CDecisionBase.mqh>            // ★フェーズF追加
#include <CLA/03_Decision/CDecisionOCOFollow.mqh>       // ★フェーズF追加
#include <CLA/03_Decision/CDecisionArbiter.mqh>         // ★フェーズF追加
#include <CLA/04_Execution/CExecutionBase.mqh>
#include <CLA/04_Execution/CExecutionManager.mqh>

//+------------------------------------------------------------------+
//| グローバルインスタンス                                            |
//+------------------------------------------------------------------+
// CLA_Data g_data; は CLA_Data.mqh 内で定義済み
CGatekeeper           g_gatekeeper;
CObservationPrice     g_observer_price;
CObservationOCOState* g_observer_oco_state = NULL;  // ポインタで宣言
CDecisionOCOFollow    g_decision_oco_follow;
CDecisionArbiter      g_decision_arbiter;
CExecutionBase*       g_execution = NULL;           // ポインタで宣言
CExecutionManager*    g_exec_manager = NULL;        // ポインタで宣言

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int AegisInit()
{
   Print("[起動] Aegis Hybrid EA (フェーズF/G/H統合版)");
   
   // ========== ポインタインスタンス作成 ==========
   g_observer_oco_state = new CObservationOCOState(InpMagicNumber);
   g_execution = new CExecutionBase(InpMagicNumber, InpSlippage);
   g_exec_manager = new CExecutionManager(InpMagicNumber, InpSlippage);
   
   if(g_observer_oco_state == NULL || g_execution == NULL || g_exec_manager == NULL)
   {
      Print("[エラー] インスタンス作成失敗");
      return INIT_FAILED;
   }
   
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
   
   if(!g_observer_oco_state.Init())
   {
      Print("[エラー] OCO状態観測初期化失敗");
      return INIT_FAILED;
   }
   
   // ========== 判断層初期化 ==========
   if(!g_decision_oco_follow.Init())
   {
      Print("[エラー] OCO判断層初期化失敗");
      return INIT_FAILED;
   }
   
   // Decision Arbiter登録
   g_decision_arbiter.RegisterDecision(&g_decision_oco_follow);
   Print("[起動] Decision Arbiter: CDecisionOCOFollow登録完了");
   
   // OCOパラメータ設定
   g_data.SetOCODistancePoints(InpOCODistancePoints);
   g_data.SetOCOLot(InpOCOLotSize);
   Print("[設定] OCO距離=", InpOCODistancePoints, "pt, ロット=", InpOCOLotSize);
   
   // ========== 実行層初期化 ==========
   if(!g_execution.Init())
   {
      Print("[エラー] 実行層初期化失敗");
      return INIT_FAILED;
   }
   
   if(!g_exec_manager.Init())
   {
      Print("[エラー] ExecutionManager初期化失敗");
      return INIT_FAILED;
   }
   
   Print("[起動完了] Aegis Hybrid EA");
   PrintFormat("[設定] コンソールログ: %s", InpEnableConsoleLog ? "表示(ON)" : "非表示(OFF)");
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void AegisDeinit(const int reason)
{
   Print("[終了] Aegis Hybrid EA");
   
   if(g_exec_manager != NULL)
   {
      g_exec_manager.Deinit();
      delete g_exec_manager;
      g_exec_manager = NULL;
   }
   
   if(g_execution != NULL)
   {
      g_execution.Deinit();
      delete g_execution;
      g_execution = NULL;
   }
   
   g_decision_oco_follow.Deinit();
   
   if(g_observer_oco_state != NULL)
   {
      g_observer_oco_state.Deinit();
      delete g_observer_oco_state;
      g_observer_oco_state = NULL;
   }
   
   g_observer_price.Deinit();
   g_gatekeeper.Deinit();
   g_data.Deinit();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void AegisTick()
{
   static ulong tick_id = 0;
   tick_id++;
   
   // ★★★ トレースログ: Tick開始 ★★★
   Print("[Aegis-TRACE][Core] ========== Tick#", tick_id, " START (", TimeToString(TimeCurrent()), ") ==========");
   
   // デバッグログ（最初の10 Tickのみ）
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
      
      if(tick_id <= 10)
      {
         Print("[DEBUG] Tick#", tick_id, " Gatekeeper遮断: ", EnumToString(gk_reason));
      }
      
      return;
   }
   
   if(tick_id <= 10)
   {
      Print("[DEBUG] Tick#", tick_id, " Gatekeeper通過");
   }
   
   // ========================================
   // Layer 2: 観測
   // ========================================
   g_observer_price.Update(g_data, tick_id);
   g_observer_oco_state.Update(g_data, tick_id);
   
   // ========================================
   // Layer 3: 判断（Decision層）
   // ========================================
   Action final_action = g_decision_arbiter.Decide(g_data, tick_id);
   
   // デバッグ用ログ（PM指示・必須）
   Print("[DEBUG][PM] Final Action type=", final_action.type, " reason=", final_action.reason);
   
   if(tick_id <= 10)
   {
      Print("[DEBUG] Tick#", tick_id, " Decision完了");
   }
   
   // ========================================
   // Layer 4: 実行
   // ========================================
   g_exec_manager.ExecuteAction(final_action, g_data, tick_id);
   
   if(tick_id <= 10)
   {
      Print("[DEBUG] Tick#", tick_id, " 完了");
   }
   
   // ★★★ トレースログ: Tick終了 ★★★
   Print("[Aegis-TRACE][Core] ========== Tick#", tick_id, " END ==========");
}
