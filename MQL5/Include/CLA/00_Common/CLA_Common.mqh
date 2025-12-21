//+------------------------------------------------------------------+
//|                                                   CLA_Common.mqh |
//|                                  Copyright 2025, Aegis Hybrid EA |
//|                                      Created by Gemini & Claude  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Aegis Hybrid EA Project"
#property link      "https://www.mql5.com"
#property strict

// インクルードガード（二重読み込み防止）
#ifndef CLA_COMMON_MQH
#define CLA_COMMON_MQH

//========================================================================
// ■ 共通定義: Aegis Hybrid EA Core Definitions
//------------------------------------------------------------------------
// [概要]
//   システム全体で使用する列挙型(Enum)、構造体(Struct)、定数を定義する。
//   このファイルは全てのモジュールから参照される「共通言語」である。
//
// [変更ルール]
//   ここを変更する場合は、全モジュールの再コンパイルが必要となるため、
//   慎重に行うこと。
//========================================================================

//------------------------------------------------------------------------
// 1. レイヤー状態定義 (ENUM_LAYER_STATUS)
//------------------------------------------------------------------------
enum ENUM_LAYER_STATUS {
   STATUS_INIT    = 0,   // 初期化中
   STATUS_OK      = 1,   // 正常稼働中
   STATUS_WARNING = 2,   // 警告（稼働は継続）
   STATUS_ERROR   = 3,   // エラー（要注意・機能制限）
   STATUS_HALT    = 4,   // 停止要求（致命的エラー）
   STATUS_NONE    = -1   // 未定義/無効
};

//------------------------------------------------------------------------
// 2. 売買シグナル種別 (ENUM_SIGNAL_TYPE)
//------------------------------------------------------------------------
enum ENUM_SIGNAL_TYPE {
   SIGNAL_NONE     = 0,   // シグナルなし
   SIGNAL_BUY      = 1,   // 買い
   SIGNAL_SELL     = -1,  // 売り
   SIGNAL_EXIT_ALL = 99   // 全決済要求
};

//------------------------------------------------------------------------
// 3. モジュール機能ID (ENUM_FUNCTION_ID)
// [規則] 文字列比較を避けるため、全ての機能・モジュールをID管理する
//------------------------------------------------------------------------
enum ENUM_FUNCTION_ID {
   // ========== Layer 0: Main Control (0-99) ==========
   FUNC_ID_MAIN_CONTROL       = 0,

   // ========== Layer 1: Gatekeeper (100-199) ==========
   FUNC_ID_GATEKEEPER         = 100, // ゲートキーパー本体
   FUNC_ID_KILL_SWITCH        = 101, // 最終防衛
   FUNC_ID_HEALTH_MONITOR     = 102, // 健全性監視

   // ========== Layer 2: Observation (200-299) ==========
   FUNC_ID_PRICE_OBSERVER     = 200, // レート監視
   FUNC_ID_TIME_SIGNAL        = 201, // 時間制御
   FUNC_ID_ECONOMIC_SIGNAL    = 202, // 経済指標
   FUNC_ID_TECHNICAL_MA       = 203, // 移動平均
   FUNC_ID_TECHNICAL_MACD     = 204, // MACD
   FUNC_ID_TECHNICAL_RSI      = 205, // RSI
   FUNC_ID_TECHNICAL_STOCH      = 206, // Stochastic
   FUNC_ID_SIGNAL_INTEGRATOR  = 210, // シグナル統合

   // ========== Layer 3: Decision (300-399) ==========
   FUNC_ID_ENVIRONMENT_JUDGE  = 300, // 環境認識
   FUNC_ID_DECISION_EVALUATOR = 301, // 総合判断
   FUNC_ID_EXTERNAL_CONFIG    = 302, // 外部設定
   FUNC_ID_HOT_RELOAD         = 303, // 動的再読み込み
   FUNC_ID_LOGIC_RSI_SIMPLE   = 310, // RSI逆張りロジック

   // ========== Layer 4: Execution (400-499) ==========
   FUNC_ID_ORDER_GENERATOR    = 400, // 注文生成
   FUNC_ID_POSITION_MANAGER   = 401, // ポジション管理
   FUNC_ID_TRAILING_MANAGER   = 402, // トレーリング
   FUNC_ID_CLOSE_JUDGE        = 403, // 決済判断

   // ========== Layer 5: Logging (500-599) ==========
   FUNC_ID_STRUCTURED_LOGGER  = 500, // 構造化ログ
   FUNC_ID_BREAKPOINT         = 501, // デバッグ地点
   FUNC_ID_NOTIFICATION       = 502, // 通知

   // ========== Base: Foundation (600-699) ==========
   FUNC_ID_EXMQL              = 600, // 抽象化層
   FUNC_ID_TIME_MANAGER       = 601, // 時間管理
   FUNC_ID_ERROR_HANDLER      = 602, // エラーハンドラ

   // ========== System Internal (900-) ==========
   FUNC_ID_CLA_DATA           = 900, // データクラス自身
   FUNC_ID_UNKNOWN            = 999  // 不明
};

//------------------------------------------------------------------------
// 4. データ構造体定義
//------------------------------------------------------------------------

// [AccessLog] 操作履歴記録用 (メモリ内リングバッファ用)
struct AccessLog {
   ulong             tick_id;     // ティックID
   ENUM_FUNCTION_ID  func_id;     // 実行モジュールID
   string            action;      // 操作内容（短文）
   datetime          time_msc;    // 実行時刻（ミリ秒精度推奨）
};

// [SignalData] 観測層から判断層へ渡すシグナル情報
struct SignalData {
   ENUM_FUNCTION_ID  source_id;   // 発信元ID (例: FUNC_ID_TECHNICAL_RSI)
   ENUM_SIGNAL_TYPE  signal_type; // 売買方向 (BUY/SELL/NONE)
   double            strength;    // 確信度 (0.0 - 1.0)
   double            price;       // シグナル発生時のレート (検証用)
   datetime          fire_time;   // 発生時刻
   
   // コンストラクタ（初期化用）
   SignalData() {
      source_id   = FUNC_ID_UNKNOWN;
      signal_type = SIGNAL_NONE;
      strength    = 0.0;
      price       = 0.0;
      fire_time   = 0;
   }
};

#endif // CLA_COMMON_MQH