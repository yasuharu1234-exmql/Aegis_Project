//+------------------------------------------------------------------+
//|                                                  CLA_Common.mqh |
//|                                  Copyright 2025, Aegis Project   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Aegis Project"
#property version     "1.20"
#property strict

#ifndef CLA_COMMON_MQH
#define CLA_COMMON_MQH

//+------------------------------------------------------------------+
//| レイヤー状態定義                                                  |
//+------------------------------------------------------------------+
enum ENUM_LAYER_STATUS
{
   STATUS_INIT    = 0,   // 初期化中
   STATUS_OK      = 1,   // 正常
   STATUS_WARNING = 2,   // 警告
   STATUS_ERROR   = 3,   // エラー
   STATUS_HALT    = 4,   // 停止
   STATUS_NONE    = -1   // 未定義
};

//+------------------------------------------------------------------+
//| シグナルタイプ定義                                                |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE     = 0,   // シグナルなし
   SIGNAL_BUY      = 1,   // 買いシグナル
   SIGNAL_SELL     = -1,  // 売りシグナル
   SIGNAL_EXIT_ALL = 99   // 全決済シグナル
};

//+------------------------------------------------------------------+
//| 機能ID定義（ENUM_FUNCTION_ID）                                    |
//| 全レイヤーの全機能を網羅した完全版                                 |
//+------------------------------------------------------------------+
enum ENUM_FUNCTION_ID
{
   FUNC_ID_NONE         = 0,
   FUNC_ID_MAIN_CONTROL = 1,
   
   // ========== Layer 0: Common (0-99) ==========
   FUNC_ID_COMMON_BASE  = 10,
   FUNC_ID_CLA_DATA     = 900,  // CLA_Dataクラス専用ID
   
   // ========== Layer 1: Gatekeeper (100-199) ==========
   FUNC_ID_GATEKEEPER    = 100,
   FUNC_ID_KILL_SWITCH   = 101,
   FUNC_ID_HEALTH_MONITOR = 102,
   
   // ========== Layer 2: Observation (200-299) ==========
   FUNC_ID_PRICE_OBSERVER   = 200,
   FUNC_ID_TIME_SIGNAL      = 201,
   FUNC_ID_ECONOMIC_SIGNAL  = 202,
   FUNC_ID_TECHNICAL_MA     = 203,
   FUNC_ID_TECHNICAL_MACD   = 204,
   FUNC_ID_TECHNICAL_RSI    = 205,
   FUNC_ID_TECHNICAL_STOCH  = 206,
   FUNC_ID_SIGNAL_INTEGRATOR = 210,
   
   // ========== Layer 3: Decision (300-399) ==========
   FUNC_ID_ENVIRONMENT_JUDGE  = 300,
   FUNC_ID_DECISION_EVALUATOR = 301,
   FUNC_ID_EXTERNAL_CONFIG    = 302,
   FUNC_ID_HOT_RELOAD         = 303,
   FUNC_ID_LOGIC_RSI_SIMPLE   = 310,
   
   // ========== Layer 4: Execution (400-499) ==========
   FUNC_ID_ORDER_GENERATOR  = 400,
   FUNC_ID_POSITION_MANAGER = 401,
   FUNC_ID_TRAILING_MANAGER = 402,
   FUNC_ID_CLOSE_JUDGE      = 403,
   
   // ========== Layer 5: Logging (500-599) ==========
   FUNC_ID_STRUCTURED_LOGGER = 500,
   FUNC_ID_BREAKPOINT        = 501,
   FUNC_ID_NOTIFICATION      = 502,
   
   // ========== Base: Foundation (600-699) ==========
   FUNC_ID_EXMQL         = 600,
   FUNC_ID_TIME_MANAGER  = 601,
   FUNC_ID_ERROR_HANDLER = 602,
   
   FUNC_ID_UNKNOWN = 999
};

//+------------------------------------------------------------------+
//| Gatekeeper判定結果（ENUM_GK_RESULT）                             |
//| レンジ分割により、原因カテゴリを明確化                             |
//+------------------------------------------------------------------+
enum ENUM_GK_RESULT
{
   // --- 0: 正常通過 ---
   GK_PASS = 0,
   
   // --- 1000番台：市場環境要因 ---
   GK_FAIL_SPREAD_HIGH      = 1001,  // スプレッド異常
   GK_FAIL_MARKET_CLOSED    = 1002,  // 市場クローズ
   GK_FAIL_TRADE_DISABLED   = 1003,  // 取引許可がない
   
   // --- 2000番台：口座資金要因 ---
   GK_FAIL_MARGIN_LOW       = 2001,  // 余剰証拠金不足
   GK_FAIL_MARGIN_LEVEL     = 2002,  // 証拠金維持率低下
   
   // --- 3000番台：データ健全性（最重要） ---
   GK_FAIL_TICK_ANOMALY     = 3001,  // Tick異常（時刻逆行）
   GK_FAIL_PRICE_INVALID    = 3002,  // 価格異常（Bid/Askがおかしい）
   GK_FAIL_TICK_GAP         = 3003,  // Tick間隔異常（データ欠落の疑い）
   
   // --- 9000番台：致命的システム要因 ---
   GK_FAIL_API_ERROR        = 9001,  // API接続エラー
   GK_FAIL_CRITICAL_ERROR   = 9002   // その他致命的エラー
};

//+------------------------------------------------------------------+
//| Execution操作要求タイプ                                          |
//+------------------------------------------------------------------+
enum ENUM_EXEC_REQUEST
{
   EXEC_REQ_NONE = 0,      // 要求なし
   EXEC_REQ_PLACE,         // 新規注文
   EXEC_REQ_MODIFY,        // 注文修正
   EXEC_REQ_CANCEL,        // 注文取消
   EXEC_REQ_CLOSE          // ポジション決済
};

//+------------------------------------------------------------------+
//| Execution状態                                                    |
//+------------------------------------------------------------------+
enum ENUM_EXEC_STATE
{
   EXEC_STATE_IDLE = 0,         // アイドル（待機中）
   EXEC_STATE_BLOCKED,          // ブロック（物理・安全条件NG）
   EXEC_STATE_IN_PROGRESS,      // 処理中（再入防止）
   EXEC_STATE_APPLIED,          // 適用完了
   EXEC_STATE_FAILED            // 失敗（非致命的）
};

//+------------------------------------------------------------------+
//| Execution結果コード                                              |
//+------------------------------------------------------------------+
enum ENUM_EXEC_RESULT
{
   EXEC_RESULT_NONE = 0,        // 未実行
   EXEC_RESULT_SUCCESS,         // 成功
   EXEC_RESULT_REQUOTE,         // リクオート（再試行可能）
   EXEC_RESULT_REJECTED,        // 拒否（一時的）
   EXEC_RESULT_INVALID_PARAMS,  // パラメータ不正
   EXEC_RESULT_FATAL_ERROR      // 致命的エラー（EA停止必要）
};

//+------------------------------------------------------------------+
//| アクセスログ構造体                                                |
//+------------------------------------------------------------------+
struct AccessLog
{
   ulong              tick_id;     // Tick ID
   ENUM_FUNCTION_ID   func_id;     // 機能ID
   string             action;      // アクション内容
   datetime           time_msc;    // タイムスタンプ
   
   AccessLog()
   {
      tick_id = 0;
      func_id = FUNC_ID_NONE;
      action = "";
      time_msc = 0;
   }
};

//+------------------------------------------------------------------+
//| シグナルデータ構造体                                              |
//+------------------------------------------------------------------+
struct SignalData
{
   ENUM_FUNCTION_ID   source_id;     // シグナル発生元
   ENUM_SIGNAL_TYPE   signal_type;   // シグナルタイプ
   double             strength;      // シグナル強度（0.0～1.0）
   double             price;         // シグナル発生価格
   datetime           fire_time;     // シグナル発生時刻
   
   SignalData()
   {
      source_id = FUNC_ID_UNKNOWN;
      signal_type = SIGNAL_NONE;
      strength = 0.0;
      price = 0.0;
      fire_time = 0;
   }
};

//+------------------------------------------------------------------+
//| Gatekeeper結果を人間が読める文字列に変換                          |
//| 用途：ログ出力、MIA分析、デバッグ                                 |
//+------------------------------------------------------------------+
string GetGKReasonText(ENUM_GK_RESULT result)
{
   switch(result)
   {
      case GK_PASS:
         return "正常通過";
      
      // 1000番台：市場環境
      case GK_FAIL_SPREAD_HIGH:
         return "スプレッド異常";
      case GK_FAIL_MARKET_CLOSED:
         return "市場クローズ";
      case GK_FAIL_TRADE_DISABLED:
         return "取引許可なし";
      
      // 2000番台：資金
      case GK_FAIL_MARGIN_LOW:
         return "余剰証拠金不足";
      case GK_FAIL_MARGIN_LEVEL:
         return "証拠金維持率低下";
      
      // 3000番台：データ健全性
      case GK_FAIL_TICK_ANOMALY:
         return "Tick時刻異常（逆行）";
      case GK_FAIL_PRICE_INVALID:
         return "価格データ異常";
      case GK_FAIL_TICK_GAP:
         return "Tick間隔異常（欠落疑い）";
      
      // 9000番台：システム
      case GK_FAIL_API_ERROR:
         return "API接続エラー";
      case GK_FAIL_CRITICAL_ERROR:
         return "致命的エラー";
      
      default:
         return StringFormat("未定義エラー(%d)", result);
   }
}

#endif // CLA_COMMON_MQH
//+------------------------------------------------------------------+