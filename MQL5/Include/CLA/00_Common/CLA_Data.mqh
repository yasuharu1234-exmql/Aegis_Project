//+------------------------------------------------------------------+
//|                                                     CLA_Data.mqh |
//|                                  Copyright 2025, Aegis Hybrid EA |
//|                                      Created by Gemini & Claude  |
//+------------------------------------------------------------------+
#property strict
#include "CLA_Common.mqh" // 共通定義を読み込み
#include "CFileLogger.mqh" // ファイルロガーを読み込み

//========================================================================
// ■ データ管理クラス: CLA_Data
//------------------------------------------------------------------------
// [概要]
//   システム全体の状態、シグナル、ログを一元管理する。
//   シングルトン(Global変数 g_data)として運用し、各モジュールには
//   参照渡し(CLA_Data &data)で伝播させる。
//
// [責務]
//   1. 操作ログの記録 (リングバッファ + ファイル出力)
//   2. 各層のステータス管理
//   3. シグナルデータの保持と提供
//
// [ログ出力先]
//   - メモリ: リングバッファ（直近100件）
//   - ファイル: UTF-8（BOM付き）CSV（Files/Aegis/Logs/）
//   - コンソール: Experts/Journal タブ
//========================================================================
class CLA_Data {
private:
   // --- メンバ変数 ---
   AccessLog         m_logs[100];      // ログ用リングバッファ
   int               m_log_index;      // 現在の書き込み位置
   ENUM_LAYER_STATUS m_layer_status[]; // 各層の状態 (配列で管理)
   CFileLogger       m_file_logger;    // ファイルロガー
   bool              m_enable_console_log; // コンソールログ出力フラグ
   
public:
   // --- コンストラクタ ---
   CLA_Data() {
      m_log_index = 0;
      m_enable_console_log = true; // デフォルトは有効
      ArrayResize(m_layer_status, 10); // とりあえず10層分確保
      ArrayInitialize(m_layer_status, STATUS_INIT);
   }

   // --- デストラクタ ---
   ~CLA_Data() {
      // 終了時に必要ならログをダンプする処理をここに書く
   }

   //---------------------------------------------------------------------
   // ■ コンソールログ出力設定
   //---------------------------------------------------------------------
   void SetConsoleLogEnabled(bool enabled) {
      m_enable_console_log = enabled;
      PrintFormat("[CLA_Data] コンソールログ出力: %s", enabled ? "有効" : "無効");
   }
   
   bool IsConsoleLogEnabled() const {
      return m_enable_console_log;
   }

   //---------------------------------------------------------------------
   // ■ 初期化メソッド
   //---------------------------------------------------------------------
   bool Init() {
      Print("[CLA_Data] 初期化開始");
      
      // ファイルロガー初期化
      if(!m_file_logger.Init())
      {
         Print("[CLA_Data] 警告: ファイルロガーの初期化に失敗しました（メモリログのみ有効）");
         // ファイルログ失敗でも続行（メモリログは有効）
      }
      
      // 初期ログ記録
      AddLog(FUNC_ID_CLA_DATA, 0, "CLA_Data Initialized");
      
      Print("[CLA_Data] 初期化完了");
      return true;
   }

   //---------------------------------------------------------------------
   // ■ ログ記録メソッド (AddLog)
   //---------------------------------------------------------------------
   void AddLog(ENUM_FUNCTION_ID func_id, ulong tick_id, string action) {
      // ========== メモリバッファへの書き込み ==========
      m_logs[m_log_index].tick_id  = tick_id;
      m_logs[m_log_index].func_id  = func_id;
      m_logs[m_log_index].action   = action;
      m_logs[m_log_index].time_msc = TimeLocal(); // 本当はミリ秒取得関数推奨
      
      // インデックスを進める (100を超えたら0に戻る)
      m_log_index++;
      if(m_log_index >= 100) m_log_index = 0;
      
      // ========== ファイルへの書き込み（重要ログのみ） ==========
      // パフォーマンス改善：通常ログはファイルに書き込まない
      if(IsImportantLog(func_id, action))
      {
         m_file_logger.WriteLog(func_id, tick_id, action, "INFO");
      }
      
      // ========== コンソール出力（制御可能） ==========
      if(m_enable_console_log)
      {
         string s_func = EnumToString(func_id);
         PrintFormat("[%s] Tick:%I64u %s", s_func, tick_id, action);
      }
   }
   
   //---------------------------------------------------------------------
   // ■ 重要ログ判定
   //---------------------------------------------------------------------
   bool IsImportantLog(ENUM_FUNCTION_ID func_id, string action) {
      // システム初期化/終了
      if(func_id == FUNC_ID_CLA_DATA) return true;
      
      // シグナル発生（🎯マーク付き）
      if(StringFind(action, "🎯") >= 0) return true;
      
      // エラー/警告/失敗
      if(StringFind(action, "エラー") >= 0) return true;
      if(StringFind(action, "警告") >= 0) return true;
      if(StringFind(action, "失敗") >= 0) return true;
      
      // 注文関連（執行層）
      if(func_id == FUNC_ID_ORDER_GENERATOR || 
         func_id == FUNC_ID_POSITION_MANAGER ||
         func_id == FUNC_ID_CLOSE_JUDGE) return true;
      
      // 初期化/終了メッセージ
      if(StringFind(action, "初期化") >= 0) return true;
      if(StringFind(action, "終了") >= 0) return true;
      
      // それ以外は記録しない（パフォーマンス優先）
      return false;
   }

   //---------------------------------------------------------------------
   // ■ レイヤー状態管理
   //---------------------------------------------------------------------
   void SetLayerStatus(ENUM_FUNCTION_ID func_id, int layer_num, ENUM_LAYER_STATUS status) {
      if(layer_num >= 0 && layer_num < ArraySize(m_layer_status)) {
         m_layer_status[layer_num] = status;
         AddLog(func_id, 0, "Status Changed: " + EnumToString(status));
      }
   }
   
   ENUM_LAYER_STATUS GetLayerStatus(int layer_num) {
      if(layer_num >= 0 && layer_num < ArraySize(m_layer_status)) {
         return m_layer_status[layer_num];
      }
      return STATUS_NONE;
   }
};

//------------------------------------------------------------------------
// ■ グローバルインスタンス定義
//------------------------------------------------------------------------
// これをIncludeした瞬間に、システム全体で使える変数 g_data が生まれる
CLA_Data g_data;