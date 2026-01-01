//+------------------------------------------------------------------+
//| File    : CFileLogger.mqh                                        |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Execution (Logger Implementation)                     |
//|                                                                  |
//| Purpose                                                          |
//|  Phase 4.5: ログ出力完成版                                        |
//|  - Log()メソッド実装                                              |
//|  - リングバッファ実装                                             |
//|  - CSV出力機能実装                                                |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#ifndef CFILELOGGER_MQH
#define CFILELOGGER_MQH

#include "ILogger.mqh"
#include "../00_Common/CLA_Common.mqh"
#include "../../EXMQL/EXMQL.mqh"  // Aegis Phase 1: StopEA()使用のため

//+------------------------------------------------------------------+
//| ログレコード構造体                                                 |
//+------------------------------------------------------------------+
struct LogRecord
{
   ushort log_id;       // ログID
   ushort tick_seq;     // Tickシーケンス（下位16bit）
   uchar level;         // ログレベル
   uchar precision;     // 精度（未使用・将来拡張用）
   ushort reserved;     // 予約（未使用・将来拡張用）
   int param1;          // パラメータ1（未使用・将来拡張用）
   int param2;          // パラメータ2（未使用・将来拡張用）
   uint time_ms;        // 時刻（ミリ秒）
};

//+------------------------------------------------------------------+
//| ファイルロガー実装（Phase 4.5完成版）                              |
//+------------------------------------------------------------------+
class CFileLogger : public ILogger
{
private:
   // ========== リングバッファ ==========
   LogRecord m_buffer[512];     // リングバッファ（固定長）
   int m_buffer_head;           // 書き込み位置
   int m_buffer_tail;           // 読み込み位置
   int m_buffer_count;          // 現在のレコード数
   int m_max_records;           // 最大記録件数
   
   // ========== 基本状態 ==========
   bool m_enabled;              // 有効フラグ
   bool m_console_log_enabled;  // コンソールログ有効
   
   // ========== ファイル管理 ==========
   string m_panic_file;         // Panicログファイル名
   
   // ========== 統計 ==========
   int m_panic_count;           // Panic発生回数

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CFileLogger()
   {
      m_buffer_head = 0;
      m_buffer_tail = 0;
      m_buffer_count = 0;
      m_max_records = 512;
      m_enabled = false;
      m_console_log_enabled = true;
      m_panic_count = 0;
      m_panic_file = "";
      
      //       ArrayInitialize(m_buffer, 0);
   }
   
   //-------------------------------------------------------------------
   //| デストラクタ                                                       |
   //-------------------------------------------------------------------
   ~CFileLogger()
   {
      if(m_enabled)
      {
         Flush();
      }
   }
   
   //-------------------------------------------------------------------
   //| 初期化                                                             |
   //-------------------------------------------------------------------
   bool Init(int max_records = 512, bool enable_console_log = true)
   {
      m_max_records = MathMin(max_records, 512); // 最大512件
      m_console_log_enabled = enable_console_log;
      m_buffer_head = 0;
      m_buffer_tail = 0;
      m_buffer_count = 0;
      m_panic_count = 0;
      
      //       ArrayInitialize(m_buffer, 0);
      
      // Panicファイル名生成
      datetime now = TimeCurrent();
      string date_str = TimeToString(now, TIME_DATE | TIME_MINUTES | TIME_SECONDS);
      StringReplace(date_str, ":", "");
      StringReplace(date_str, " ", "_");
      StringReplace(date_str, ".", "");
      
      m_panic_file = "aegis_panic_" + date_str + ".log";
      
      m_enabled = true;
      
      Print("[Logger] Phase 4.5 初期化完了: 最大件数=", m_max_records, 
            ", コンソールログ=", (m_console_log_enabled ? "ON" : "OFF"));
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| ログ記録（Phase 4.5: 本実装）                                      |
   //-------------------------------------------------------------------
   virtual void Log(int log_id,
                    uchar level,
                    int p1 = 0,
                    int p2 = 0) override
   {
      if(!m_enabled)
         return;
      
      // リングバッファに追加
      LogRecord record;
      record.log_id = (ushort)log_id;
      record.tick_seq = (ushort)(GetTickCount() & 0xFFFF); // 下位16bit
      record.level = level;
      record.precision = 0;
      record.reserved = 0;
      record.param1 = p1;
      record.param2 = p2;
      record.time_ms = (uint)(TimeLocal() * 1000); // ミリ秒（簡易実装）
      
      // バッファに書き込み
      m_buffer[m_buffer_head] = record;
      m_buffer_head = (m_buffer_head + 1) % m_max_records;
      
      // カウント更新
      if(m_buffer_count < m_max_records)
      {
         m_buffer_count++;
      }
      else
      {
         // 満杯の場合は tail を進める（古いレコードを上書き）
         m_buffer_tail = (m_buffer_tail + 1) % m_max_records;
      }
      
      // コンソールログ
      if(m_console_log_enabled)
      {
         PrintFormat("[%s] [%s] Tick=%d P1=%d P2=%d", 
                     GetLevelName(level), 
                     GetLogName(log_id), 
                     record.tick_seq,
                     p1,
                     p2);
      }
   }
   
   //-------------------------------------------------------------------
   //| Panicログ（Phase 1実装・変更なし）                                 |
   //-------------------------------------------------------------------
   virtual void Panic(int panic_id,
                      const string &message) override
   {
      m_panic_count++;
      
      // ========== 即座にPrint出力（人間通知） ==========
      string panic_type = GetPanicTypeName(panic_id);
      Print("************************************************");
      Print("*** PANIC *** EA停止");
      Print("Log ID: ", panic_id, " (", panic_type, ")");
      Print("Reason: ", message);
      Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
      Print("Count: ", m_panic_count);
      Print("ログファイルを確認してください");
      Print("************************************************");
      
      // ========== ファイルに記録 ==========
      WritePanicToFile(panic_id, message);
      
      // ========== 即Flush ==========
      Flush();
      
      // ========== EA停止 ==========
      exMQL.StopEA();
   }
   
   //-------------------------------------------------------------------
   //| Flush（Phase 4.5: CSV出力実装）                                    |
   //-------------------------------------------------------------------
   virtual void Flush() override
   {
      if(!m_enabled)
         return;
      
      if(m_buffer_count == 0)
      {
         Print("[Logger] Flush: レコードなし");
         return;
      }
      
      // ファイル名生成
      MqlDateTime dt;
      TimeToStruct(TimeLocal(), dt);
      string filename = StringFormat("Aegis_Logs/%04d%02d%02d_%02d%02d%02d.csv", dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
      
      // ファイルオープン
      int handle = FileOpen(filename, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON, ',');
      if(handle == INVALID_HANDLE)
      {
         Print("[CFileLogger] ファイルオープン失敗: ", filename, " Error=", GetLastError());
         return;
      }
      
      // ヘッダー書き込み
      FileWrite(handle, "Time_ms", "TickSeq", "Level", "LogID", "LogName", "Param1", "Param2");
      
      // レコード書き込み
      int index = m_buffer_tail;
      for(int i = 0; i < m_buffer_count; i++)
      {
         LogRecord rec = m_buffer[index];
         
         FileWrite(handle, 
                   (string)rec.time_ms,
                   (string)rec.tick_seq,
                   GetLevelName(rec.level),
                   (string)rec.log_id,
                   GetLogName(rec.log_id),
                   (string)rec.param1,
                   (string)rec.param2);
         
         index = (index + 1) % m_max_records;
      }
      
      FileClose(handle);
      Print("[CFileLogger] ログ出力完了: ", filename, " (", m_buffer_count, " records)");
      
      // バッファクリア
      m_buffer_head = 0;
      m_buffer_tail = 0;
      m_buffer_count = 0;
   }
   
   //-------------------------------------------------------------------
   //| 統計取得                                                           |
   //-------------------------------------------------------------------
   int GetLogCount() const { return m_buffer_count; }
   int GetPanicCount() const { return m_panic_count; }
   
private:
   //-------------------------------------------------------------------
   //| ログID → 文字列変換                                                |
   //-------------------------------------------------------------------
   string GetLogName(int log_id)
   {
      switch(log_id)
      {
         case LOG_ID_EXEC_PLACE:  return "PLACE";
         case LOG_ID_EXEC_MODIFY: return "MODIFY";
         case LOG_ID_EXEC_CANCEL: return "CANCEL";
         case LOG_ID_EXEC_CLOSE:  return "CLOSE";
         default: return StringFormat("ID_%d", log_id);
      }
   }
   
   //-------------------------------------------------------------------
   //| ログレベル → 文字列変換                                            |
   //-------------------------------------------------------------------
   string GetLevelName(int level)
   {
      switch(level)
      {
         case LOG_LEVEL_DEBUG:    return "DEBUG";
         case LOG_LEVEL_INFO:     return "INFO";
         case LOG_LEVEL_WARNING:  return "WARNING";
         case LOG_LEVEL_ERROR:    return "ERROR";
         case LOG_LEVEL_CRITICAL: return "CRITICAL";
         default: return "UNKNOWN";
      }
   }
   
   //-------------------------------------------------------------------
   //| PanicタイプID → 文字列変換                                         |
   //-------------------------------------------------------------------
   string GetPanicTypeName(int panic_id)
   {
      switch(panic_id)
      {
         case PANIC_UNKNOWN:             return "原因不明の異常";
         case PANIC_MEMORY_CORRUPTION:   return "メモリ破損検知";
         case PANIC_ORDER_STATE_BROKEN:  return "注文状態の不整合";
         case PANIC_EXECUTION_INCONSIST: return "実行層の不整合";
         case PANIC_LOGGER_FAILURE:      return "Logger自体の失敗";
         case PANIC_INTERNAL_ASSERT:     return "内部アサーション違反";
         case PANIC_MANUAL_TRIGGER:      return "手動トリガー";
         default: return "不明なPanic";
      }
   }
   
   //-------------------------------------------------------------------
   //| Panicログをファイルに書き込み                                      |
   //-------------------------------------------------------------------
   void WritePanicToFile(int panic_id, const string &message)
   {
      int handle = FileOpen(m_panic_file, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
      if(handle == INVALID_HANDLE)
      {
         Print("[CFileLogger] Panicファイルオープン失敗: ", m_panic_file);
         return;
      }
      
      string panic_type = GetPanicTypeName(panic_id);
      string time_str = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
      
      FileWrite(handle, "=================================");
      FileWrite(handle, "PANIC DETECTED");
      FileWrite(handle, "=================================");
      FileWrite(handle, "Time: " + time_str);
      FileWrite(handle, "Panic ID: " + (string)panic_id);
      FileWrite(handle, "Type: " + panic_type);
      FileWrite(handle, "Reason: " + message);
      FileWrite(handle, "Count: " + (string)m_panic_count);
      FileWrite(handle, "=================================");
      
      FileClose(handle);
   }
};

#endif
