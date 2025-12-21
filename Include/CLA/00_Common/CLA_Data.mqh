//+------------------------------------------------------------------+
//|                                                    CLA_Data.mqh |
//|                                  Copyright 2025, Aegis Project   |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Aegis Project"
#property version     "1.20"
#property strict

#include "CLA_Common.mqh"
#include "CFileLogger.mqh"

//+------------------------------------------------------------------+
//| グローバルデータ管理クラス                                         |
//| 役割：全レイヤー間でのデータ共有、ログ管理                          |
//+------------------------------------------------------------------+
class CLA_Data
{
private:
   // ========== ログ管理 ==========
   CFileLogger m_logger;                    // ファイルロガー
   bool        m_console_log_enabled;       // コンソールログ有効フラグ
   
   // ========== メモリバッファ（重要ログフィルタ用） ==========
   string      m_log_buffer[];              // 全ログをメモリに保持
   int         m_log_buffer_size;           // バッファサイズ
   int         m_log_buffer_count;          // 現在のログ数
   
   // ========== レイヤー状態管理 ==========
   ENUM_LAYER_STATUS m_layer_status[6];     // 各レイヤーの状態
   
   // ========== 市場データ ==========
   double      m_current_bid;               // 現在のBid価格
   double      m_current_ask;               // 現在のAsk価格
   double      m_current_spread;            // 現在のスプレッド
   datetime    m_current_time;              // 現在時刻
   
   // ========== 観測データ ==========
   double      m_rsi_value;                 // RSI値
   
   // ========== Gatekeeper状態（Phase 2追加） ==========
   ENUM_GK_RESULT m_last_gk_result;         // 最後のGatekeeper判定結果
   
public:
   //+------------------------------------------------------------------+
   //| コンストラクタ                                                    |
   //+------------------------------------------------------------------+
   CLA_Data()
   {
      m_console_log_enabled = false;
      m_log_buffer_size = 10000;  // 10000行分のログをメモリに保持
      m_log_buffer_count = 0;
      ArrayResize(m_log_buffer, m_log_buffer_size);
      
      // レイヤー状態初期化
      for(int i = 0; i < 6; i++)
      {
         m_layer_status[i] = STATUS_NONE;
      }
      
      // データ初期化
      m_current_bid = 0.0;
      m_current_ask = 0.0;
      m_current_spread = 0.0;
      m_current_time = 0;
      m_rsi_value = 0.0;
      
      // Gatekeeper初期化
      m_last_gk_result = GK_PASS;
   }
   
   //+------------------------------------------------------------------+
   //| 初期化                                                           |
   //+------------------------------------------------------------------+
   bool Init()
   {
      if(!m_logger.Init())
      {
         Print("[エラー] ファイルロガー初期化失敗");
         return false;
      }
      
      AddLog(FUNC_ID_CLA_DATA, 0, "CLA_Data初期化完了");
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| 終了処理                                                         |
   //+------------------------------------------------------------------+
   void Deinit()
   {
      AddLog(FUNC_ID_CLA_DATA, 0, "CLA_Data終了処理", true);
      // CFileLoggerは都度クローズのためDeinit不要
   }
   
   //+------------------------------------------------------------------+
   //| コンソールログ有効/無効設定                                        |
   //+------------------------------------------------------------------+
   void SetConsoleLogEnabled(bool enabled)
   {
      m_console_log_enabled = enabled;
   }
   
   //+------------------------------------------------------------------+
   //| ログ追加（重要ログフィルタ対応版）                                 |
   //| important=trueの場合のみファイル出力                              |
   //+------------------------------------------------------------------+
   void AddLog(ENUM_FUNCTION_ID func_id, ulong tick_id, string message, bool important = false)
   {
      // ログレベルを決定（importantフラグから）
      string level = important ? "IMPORTANT" : "DEBUG";
      
      // メモリバッファに保存（常に保存・簡易フォーマット）
      if(m_log_buffer_count < m_log_buffer_size)
      {
         string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
         string log_line = StringFormat("%s,Tick#%llu,Func#%d,%s",
                                        timestamp,
                                        tick_id,
                                        func_id,
                                        message);
         m_log_buffer[m_log_buffer_count] = log_line;
         m_log_buffer_count++;
      }
      
      // 重要ログのみファイル出力
      if(important)
      {
         m_logger.WriteLog(func_id, tick_id, message, level);
      }
      
      // コンソール出力（設定による）
      if(m_console_log_enabled)
      {
         PrintFormat("[%s] Tick#%llu Func#%d: %s", level, tick_id, func_id, message);
      }
   }
   
   //+------------------------------------------------------------------+
   //| 全ログをファイルに出力（デバッグ用）                               |
   //+------------------------------------------------------------------+
   void FlushAllLogs()
   {
      // メモリバッファの全ログをファイルに書き出す
      for(int i = 0; i < m_log_buffer_count; i++)
      {
         // バッファには簡易フォーマットで保存されているため
         // ここでは全て「DEBUG」レベルとして出力
         m_logger.WriteLog(FUNC_ID_CLA_DATA, i, m_log_buffer[i], "DEBUG");
      }
      
      string flush_msg = StringFormat("全ログ出力完了: %d件", m_log_buffer_count);
      m_logger.WriteLog(FUNC_ID_CLA_DATA, 0, flush_msg, "IMPORTANT");
      
      if(m_console_log_enabled)
      {
         Print("[CLA_Data] ", flush_msg);
      }
   }
   
   //+------------------------------------------------------------------+
   //| レイヤー状態設定                                                  |
   //+------------------------------------------------------------------+
   void SetLayerStatus(int layer_num, ENUM_LAYER_STATUS status)
   {
      if(layer_num >= 0 && layer_num < ArraySize(m_layer_status))
      {
         m_layer_status[layer_num] = status;
      }
   }
   
   //+------------------------------------------------------------------+
   //| レイヤー状態取得                                                  |
   //+------------------------------------------------------------------+
   ENUM_LAYER_STATUS GetLayerStatus(int layer_num)
   {
      if(layer_num >= 0 && layer_num < ArraySize(m_layer_status))
      {
         return m_layer_status[layer_num];
      }
      return STATUS_NONE;
   }
   
   //+------------------------------------------------------------------+
   //| 市場データ設定                                                    |
   //+------------------------------------------------------------------+
   void SetMarketData(double bid, double ask, double spread, datetime time)
   {
      m_current_bid = bid;
      m_current_ask = ask;
      m_current_spread = spread;
      m_current_time = time;
   }
   
   //+------------------------------------------------------------------+
   //| RSI値設定                                                        |
   //+------------------------------------------------------------------+
   void SetRSI(double rsi)
   {
      m_rsi_value = rsi;
   }
   
   //+------------------------------------------------------------------+
   //| RSI値取得                                                        |
   //+------------------------------------------------------------------+
   double GetRSI() const
   {
      return m_rsi_value;
   }
   
   //+------------------------------------------------------------------+
   //| Gatekeeper結果設定（Phase 2追加）                                |
   //| 異常時は自動的にログ記録を行う                                     |
   //+------------------------------------------------------------------+
   void SetGatekeeperResult(ENUM_GK_RESULT result, ulong tick_id = 0)
   {
      m_last_gk_result = result;
      
      // 正常(PASS)以外ならログに残す
      if(result != GK_PASS)
      {
         string reason_text = GetGKReasonText(result);
         string log_msg = StringFormat("⛔ Gatekeeper遮断: %s", reason_text);
         
         // 重要ログとして記録（MIA分析用）
         AddLog(FUNC_ID_GATEKEEPER, tick_id, log_msg, true);
      }
   }
   
   //+------------------------------------------------------------------+
   //| Gatekeeper結果取得（Phase 2追加）                                |
   //+------------------------------------------------------------------+
   ENUM_GK_RESULT GetGatekeeperResult() const
   {
      return m_last_gk_result;
   }
};

//+------------------------------------------------------------------+
//| グローバルインスタンス                                             |
//| ★★★ 超重要：これがないとAegis_Coreでエラーになる ★★★            |
//+------------------------------------------------------------------+
CLA_Data g_data;

//+------------------------------------------------------------------+
