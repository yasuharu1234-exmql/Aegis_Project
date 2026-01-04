//+------------------------------------------------------------------+
//| File    : CLA_Common.mqh                                         |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Common (Shared Definitions)                            |
//|                                                                  |
//| Role                                                             |
//|  - Aegis全体で共有される定数・列挙型・共通構造体を定義する       |
//|  - レイヤー間通信の「共通語彙」を提供する                        |
//|                                                                  |
//| Design Policy                                                    |
//|  - このファイルは「定義のみ」を扱う                              |
//|  - ロジック・状態・実装コードは一切含めない                      |
//|  - 既存定義の意味・名前は変更しない                              |
//|                                                                  |
//| Phase 2 Notes                                                    |
//|  - Execution層との接続に必要な型が追加される予定                 |
//|  - 既存コードとの後方互換性を最優先とする                        |
//|                                                                  |
//| Phase 6 Notes                                                    |
//|  - 状態ログ用のENUM_LOG_ID（100番台）を追加                      |
//|                                                                  |
//| Change Policy                                                    |
//|  - 追加は可、削除・改名・意味変更は禁止                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property version     "1.21"
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
//| Panic ログ ID（Phase 1 - Logger）                                |
//| なりふり構わない緊急ログ用                                        |
//+------------------------------------------------------------------+
enum ENUM_PANIC_LOG_ID
{
   PANIC_UNKNOWN              = 9000,  // 原因不明の異常
   PANIC_MEMORY_CORRUPTION    = 9001,  // メモリ破損検知
   PANIC_ORDER_STATE_BROKEN   = 9002,  // 注文状態の不整合
   PANIC_EXECUTION_INCONSIST  = 9003,  // 実行層の不整合
   PANIC_LOGGER_FAILURE       = 9004,  // Logger自体の失敗
   PANIC_INTERNAL_ASSERT      = 9005,  // 内部アサーション違反
   PANIC_MANUAL_TRIGGER       = 9099   // 手動トリガー
};

//+------------------------------------------------------------------+
//| 通常ログ ID（Phase 3 - Execution / Phase 6 - State Log）         |
//| 実行層の処理ログ用 + 状態遷移ログ用                               |
//+------------------------------------------------------------------+
enum ENUM_LOG_ID
{
   // ========== Phase 6 追加：状態ログ用（100番台） ==========
   LOG_ID_OCO_PLACE      = 100,  // OCO配置成功
   LOG_ID_MODIFY_TRY     = 101,  // MODIFY試行
   LOG_ID_MODIFY_OK      = 102,  // MODIFY成功
   LOG_ID_MODIFY_FAIL    = 103,  // MODIFY失敗
   LOG_ID_NO_CHANGE      = 104,  // 価格変更なし（初回のみ）
   LOG_ID_SPREAD_SKIP    = 105,  // スプレッド超過で追従スキップ
   LOG_ID_SPREAD_OK      = 106,  // スプレッド正常（状態遷移時のみ）
   LOG_ID_TRAIL_TRIGGER  = 107,  // 追従トリガー発動
   LOG_ID_CANCEL_OK      = 108,  // キャンセル成功
   LOG_ID_FILL_DETECT    = 109,  // 約定検出
   LOG_ID_RSI_DECISION   = 110,  // RSI判断
   LOG_ID_DECISION_SKIP  = 111,  // 判断スキップ（何もしなかった理由）
   
   // ========== 将来の拡張用 ==========
   LOG_ID_GATEKEEPER    = 1000,  // Gatekeeper層
   LOG_ID_OBSERVATION   = 2000,  // Observation層
   
   // ========== Execution層（3000番台） ==========
   LOG_ID_EXEC_PLACE    = 3001,  // 注文配置
   LOG_ID_EXEC_MODIFY   = 3002,  // 注文修正
   LOG_ID_EXEC_CANCEL   = 3003,  // 注文取消
   LOG_ID_EXEC_CLOSE    = 3004,  // ポジション決済
   
   // ========== 将来の拡張用 ==========
   LOG_ID_DECISION      = 4000,  // Decision層
   LOG_ID_STRATEGY      = 5000   // Strategy層
};

//+------------------------------------------------------------------+
//| ログレベル（Phase 3 - Logger）                                    |
//+------------------------------------------------------------------+
enum ENUM_LOG_LEVEL
{
   LOG_LEVEL_DEBUG    = 0,  // デバッグ情報
   LOG_LEVEL_INFO     = 1,  // 一般情報
   LOG_LEVEL_WARNING  = 2,  // 警告
   LOG_LEVEL_ERROR    = 3,  // エラー
   LOG_LEVEL_CRITICAL = 4   // 致命的エラー
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

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| フェーズC追加: Action定義（判断層の出力）                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Action種別                                                        |
//| [Purpose]                                                         |
//|   判断層が出力する「意思決定の結果」を表す記号                     |
//|   フェーズCでは最小構造のみ                                       |
//|                                                                  |
//| [Design Philosophy]                                               |
//|   - ACTION_NONEも立派なAction（何もしないという意思決定）         |
//|   - 実行命令ではなく、意思決定の結果を表す                        |
//|   - パラメータはフェーズD以降で追加                               |
//+------------------------------------------------------------------+
enum ENUM_ACTION_TYPE
{
   ACTION_NONE = 0,      // 何もしない（重要: これも意思決定）
   ACTION_OCO_PLACE,     // OCO注文配置
   ACTION_OCO_MODIFY,    // OCO注文変更
   ACTION_OCO_CANCEL     // OCO注文キャンセル
};

//+------------------------------------------------------------------+
//| Action構造体（フェーズF-1: フィールド拡張）                        |
//| [Fields]                                                          |
//|   type         : Action種別                                       |
//|   buy_price    : BuyStop価格（PLACE/MODIFY時）                    |
//|   sell_price   : SellStop価格（PLACE/MODIFY時）                   |
//|   lot          : 注文ロット（PLACE時のみ使用）                     |
//|   sl           : ストップロス（PLACE時、将来のBE/Trailing時）       |
//|   tp           : テイクプロフィット（PLACE時、将来のTP圧縮時）      |
//|   target_ticket: 変更/取消対象チケット（MODIFY/CANCEL時）          |
//|   reason       : この判断に至った理由（ログ・デバッグ用）           |
//|   max_slippage : 許容スリッページ（pips）                          |
//|   max_retry    : 最大リトライ回数                                  |
//|                                                                  |
//| [Usage by Action Type]                                            |
//|   ACTION_OCO_PLACE:                                               |
//|     必須: buy_price, sell_price, lot, sl, tp                     |
//|     任意: reason, max_slippage, max_retry                        |
//|   ACTION_OCO_MODIFY:                                              |
//|     必須: buy_price, sell_price                                  |
//|     任意: reason, max_retry                                      |
//|   ACTION_OCO_CANCEL:                                              |
//|     必須: target_ticket                                          |
//|     任意: reason, max_retry                                      |
//+------------------------------------------------------------------+
struct Action
{
   ENUM_ACTION_TYPE type;
   
   // ===== 価格情報 =====
   double buy_price;
   double sell_price;
   
   // ===== ロット情報 =====
   double lot;
   
   // ===== SL/TP情報 =====
   double sl;
   double tp;
   
   // ===== チケット情報 =====
   ulong target_ticket;
   
   // ===== ログ用 =====
   string reason;
   
   // ===== 実行制約 =====
   int max_slippage;
   int max_retry;
   
   // ===== コンストラクタ（初期化） =====
   Action()
   {
      type           = ACTION_NONE;
      buy_price      = 0.0;
      sell_price     = 0.0;
      lot            = 0.0;
      sl             = 0.0;
      tp             = 0.0;
      target_ticket  = 0;
      reason         = "";
      max_slippage   = 0;
      max_retry      = 0;
   }
};
#endif // CLA_COMMON_MQH
//+------------------------------------------------------------------+