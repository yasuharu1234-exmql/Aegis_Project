//+------------------------------------------------------------------+
//| File    : CFileLogger.mqh                                        |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Execution (Logger Implementation)                     |
//|                                                                  |
//| Purpose                                                          |
//|  Phase 6 Task 2: 10カラムCSV出力対応                             |
//|  - LogRecord構造体拡張（param3, param4, log_name, message追加）  |
//|  - Log()メソッド拡張（6パラメータ対応）                          |
//|  - GetLogName()完全実装（100番台対応）                           |
//|  - Flush() CSV出力実装（10カラム）                               |
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
//| ログレコード構造体（Phase 6 Task 2拡張版）                        |
//+------------------------------------------------------------------+
struct LogRecord
{
   ushort log_id;       // ログID
   ushort tick_seq;     // Tickシーケンス（下位16bit）
   uchar level;         // ログレベル
   uchar precision;     // 精度（未使用・将来拡張用）
   ushort reserved;     // 予約（未使用・将来拡張用）
   int param1;          // パラメータ1
   int param2;          // パラメータ2
   int param3;          // パラメータ3 ★Phase 6追加
   int param4;          // パラメータ4 ★Phase 6追加
   uint time_ms;        // 時刻（ミリ秒）
   string log_name;     // ログ名称（最大32文字）★Phase 6追加
   string message;      // 説明文（最大256文字）★Phase 6追加
};

//+------------------------------------------------------------------+
//| ファイルロガー実装（Phase 6対応版）                               |
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
   
   // ========== 状態管理 ==========
   bool m_enabled;              // ロガー有効フラグ
   bool m_console_log_enabled;  // コンソールログ有効フラグ
   int m_panic_count;           // Panic発生回数
   
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CFileLogger()
   {
      m_enabled = true;
      m_console_log_enabled = false;  // デフォルトはコンソールログOFF
      m_panic_count = 0;
      m_buffer_head = 0;
      m_buffer_tail = 0;
      m_buffer_count = 0;
      m_max_records = 512;
   }
   
   //-------------------------------------------------------------------
   //| 初期化                                                            |
   //-------------------------------------------------------------------
   bool Init()
   {
      m_enabled = true;
      m_buffer_head = 0;
      m_buffer_tail = 0;
      m_buffer_count = 0;
      
      Print("[CFileLogger] 初期化完了");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理                                                          |
   //-------------------------------------------------------------------
   void Deinit()
   {
      // 残っているログをFlush
      Flush();
      Print("[CFileLogger] 終了処理完了");
   }
   
   //-------------------------------------------------------------------
   //| ロガー有効化/無効化                                               |
   //-------------------------------------------------------------------
   void Enable() { m_enabled = true; }
   void Disable() { m_enabled = false; }
   bool IsEnabled() const { return m_enabled; }
   
   //-------------------------------------------------------------------
   //| コンソールログ有効化/無効化                                        |
   //-------------------------------------------------------------------
   void EnableConsoleLog(bool enable) { m_console_log_enabled = enable; }
   
   //-------------------------------------------------------------------
   //| ログ記録（基本版: ILogger準拠）                                    |
   //-------------------------------------------------------------------
   virtual void Log(int log_id,
                    uchar level,
                    int p1 = 0,
                    int p2 = 0) override
   {
      // 拡張版を呼び出し
      Log(log_id, level, p1, p2, 0, 0, "");
   }
   
   //-------------------------------------------------------------------
   //| ログ記録（Phase 6拡張版: 6パラメータ対応）                         |
   //-------------------------------------------------------------------
   void Log(int log_id,
            uchar level,
            int p1,
            int p2,
            int p3,
            int p4,
            string msg)
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
      record.param3 = p3;            // ★Phase 6追加
      record.param4 = p4;            // ★Phase 6追加
      record.time_ms = (uint)(TimeLocal() * 1000); // ミリ秒（簡易実装）
      record.log_name = GetLogName(log_id);  // ★Phase 6追加
      record.message = msg;          // ★Phase 6追加
      
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
         PrintFormat("[%s] [%s] Tick=%d P1=%d P2=%d P3=%d P4=%d %s", 
                     GetLevelName(level), 
                     record.log_name, 
                     record.tick_seq,
                     p1, p2, p3, p4,
                     msg);
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
   //| Flush（Phase 6: 10カラムCSV出力実装）                             |
   //-------------------------------------------------------------------
   virtual void Flush() override
   {
      if(!m_enabled || m_buffer_count == 0)
         return;
      
      // ファイル名生成
      datetime now = TimeCurrent();
      string filename = "StateLog_" + TimeToString(now, TIME_DATE) + ".csv";
      StringReplace(filename, ".", "");
      
      // ファイルオープン（追記モード）
      int handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ',');
      if(handle == INVALID_HANDLE)
      {
         Print("[Logger] ファイルオープン失敗: ", filename, " Error=", GetLastError());
         return;
      }
      
      // ヘッダー出力（ファイルサイズ0の場合のみ）
      if(FileSize(handle) == 0)
      {
         FileWrite(handle, "Time_ms", "TickSeq", "Level", "LogID", "LogName", 
                   "Param1", "Param2", "Param3", "Param4", "Message");
      }
      
      // バッファからCSV出力
      for(int i = 0; i < m_buffer_count; i++)
      {
         int idx = (m_buffer_tail + i) % m_max_records;
         LogRecord rec = m_buffer[idx];
         
         string level_str = GetLevelName(rec.level);
         string msg_escaped = EscapeCSV(rec.message);
         
         FileWrite(handle, 
                   rec.time_ms,
                   rec.tick_seq,
                   level_str,
                   rec.log_id,
                   rec.log_name,
                   rec.param1,
                   rec.param2,
                   rec.param3,
                   rec.param4,
                   msg_escaped);
      }
      
      FileClose(handle);
      
      // バッファクリア
      m_buffer_count = 0;
      m_buffer_head = 0;
      m_buffer_tail = 0;
      
      Print("[Logger] Flush完了: ", m_buffer_count, "件出力 -> ", filename);
   }
   
   //-------------------------------------------------------------------
   //| 統計取得                                                           |
   //-------------------------------------------------------------------
   int GetLogCount() const { return m_buffer_count; }
   int GetPanicCount() const { return m_panic_count; }
   
private:
   //-------------------------------------------------------------------
   //| CSV エスケープ処理（Phase 6追加）                                  |
   //-------------------------------------------------------------------
   string EscapeCSV(string text)
   {
      if(StringFind(text, ",") >= 0 || 
         StringFind(text, "\n") >= 0 || 
         StringFind(text, "\"") >= 0)
      {
         StringReplace(text, "\"", "\"\"");
         return "\"" + text + "\"";
      }
      return text;
   }
   
   //-------------------------------------------------------------------
   //| ログID → 文字列変換（Phase 6完全実装）                             |
   //-------------------------------------------------------------------
   string GetLogName(int log_id)
   {
      switch(log_id)
      {
         // ========== 100番台: Phase 6 通常状態ログ ==========
         case 100: return "OCO_PLACE";
         case 101: return "MODIFY_TRY";
         case 102: return "MODIFY_OK";
         case 103: return "MODIFY_FAIL";
         case 104: return "NO_CHANGE";
         case 105: return "SPREAD_SKIP";
         case 106: return "SPREAD_OK";
         case 107: return "TRAIL_TRIGGER";
         case 108: return "CANCEL_OK";
         case 109: return "FILL_DETECT";
         case 110: return "DECISION";
         case 111: return "DECISION_SKIP";
         
         // ========== 3000番台: 実行層ログ（既存） ==========
         case 3001: return "EXEC_PLACE";
         case 3002: return "EXEC_MODIFY";
         case 3003: return "EXEC_CANCEL";
         case 3004: return "EXEC_CLOSE";
         
         default: return "UNKNOWN";
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
         case LOG_LEVEL_WARNING:  return "WARN";
         case LOG_LEVEL_ERROR:    return "ERROR";
         case LOG_LEVEL_CRITICAL: return "CRITICAL";
         default:                 return "UNKNOWN";
      }
   }
   
   //-------------------------------------------------------------------
   //| Panicタイプ名取得                                                  |
   //-------------------------------------------------------------------
   string GetPanicTypeName(int panic_id)
   {
      switch(panic_id)
      {
         case PANIC_UNKNOWN:             return "UNKNOWN";
         case PANIC_MEMORY_CORRUPTION:   return "MEMORY_CORRUPTION";
         case PANIC_ORDER_STATE_BROKEN:  return "ORDER_STATE_BROKEN";
         case PANIC_EXECUTION_INCONSIST: return "EXECUTION_INCONSIST";
         case PANIC_LOGGER_FAILURE:      return "LOGGER_FAILURE";
         case PANIC_INTERNAL_ASSERT:     return "INTERNAL_ASSERT";
         case PANIC_MANUAL_TRIGGER:      return "MANUAL_TRIGGER";
         default: return StringFormat("PANIC_%d", panic_id);
      }
   }
   
   //-------------------------------------------------------------------
   //| Panicログをファイルに記録                                          |
   //-------------------------------------------------------------------
   void WritePanicToFile(int panic_id, const string &message)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      string filename = StringFormat("Aegis_Logs/PANIC_%04d%02d%02d_%02d%02d%02d.txt", 
                                     dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
      
      int handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
      if(handle == INVALID_HANDLE)
      {
         Print("[CFileLogger] Panicファイル作成失敗");
         return;
      }
      
      FileWrite(handle, "************************************************");
      FileWrite(handle, "*** PANIC LOG ***");
      FileWrite(handle, "Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
      FileWrite(handle, "Panic ID: " + IntegerToString(panic_id));
      FileWrite(handle, "Type: " + GetPanicTypeName(panic_id));
      FileWrite(handle, "Message: " + message);
      FileWrite(handle, "Count: " + IntegerToString(m_panic_count));
      FileWrite(handle, "************************************************");
      
      FileClose(handle);
      Print("[CFileLogger] Panicログ記録完了: ", filename);
   }
};

#endif // CFILELOGGER_MQH
