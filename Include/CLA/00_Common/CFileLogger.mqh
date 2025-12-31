//+------------------------------------------------------------------+
//| File    : CFileLogger.mqh                                        |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Execution (Logger Implementation)                     |
//|                                                                  |
//| Purpose                                                          |
//|  Phase 1: 最小実装のファイルロガー                               |
//|  - Panic()だけは本気実装                                         |
//|  - Log()は仮実装（Printでも可）                                  |
//|  - 将来の本実装への差し替え前提                                  |
//|                                                                  |
//| Design Policy                                                    |
//|  - これは「足場」である                                          |
//|  - 美しくなくていい                                              |
//|  - 壊れなければいい                                              |
//|  - 将来削除・拡張できる                                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#ifndef CFILELOGGER_MQH
#define CFILELOGGER_MQH

#include "ILogger.mqh"
#include "../00_Common/CLA_Common.mqh"

//+------------------------------------------------------------------+
//| ファイルロガー実装（Phase 1）                                     |
//+------------------------------------------------------------------+
class CFileLogger : public ILogger
{
private:
   // ========== 基本状態 ==========
   bool     m_enabled;           // 有効フラグ
   int      m_count;             // ログ件数
   int      m_max_records;       // 最大件数
   
   // ========== ファイル管理 ==========
   string   m_panic_file;        // Panicログファイル名
   
   // ========== 統計 ==========
   int      m_panic_count;       // Panic発生回数

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CFileLogger()
   {
      m_enabled = false;
      m_count = 0;
      m_max_records = 10000;
      m_panic_count = 0;
      m_panic_file = "";
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
   bool Init(int max_records = 10000)
   {
      m_max_records = max_records;
      m_count = 0;
      m_panic_count = 0;
      
      // Panicファイル名生成
      datetime now = TimeCurrent();
      string date_str = TimeToString(now, TIME_DATE | TIME_MINUTES | TIME_SECONDS);
      StringReplace(date_str, ":", "");
      StringReplace(date_str, " ", "_");
      StringReplace(date_str, ".", "");
      
      m_panic_file = "aegis_panic_" + date_str + ".log";
      
      m_enabled = true;
      
      Print("[Logger] Phase 1 初期化完了: 最大件数=", m_max_records);
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 通常ログ（Phase 1: 仮実装）                                        |
   //-------------------------------------------------------------------
   virtual void Log(int log_id,
                    uchar level,
                    int p1 = 0,
                    int p2 = 0) override
   {
      if(!m_enabled)
         return;
      
      // Phase 1: Printで代用（将来は配列に保存）
      // Print("[Log] ID=", log_id, " Level=", level, " P1=", p1, " P2=", p2);
      
      // 件数のみカウント
      m_count++;
      
      // 最大件数到達時の処理（Phase 1では何もしない）
      if(m_count >= m_max_records)
      {
         // 将来: リングバッファなど
      }
   }
   
   //-------------------------------------------------------------------
   //| Panicログ（Phase 1: 本気実装）                                     |
   //-------------------------------------------------------------------
   virtual void Panic(int panic_id,
                      const string &message) override
   {
      m_panic_count++;
      
      // ========== 即座にPrint出力 ==========
      string panic_type = GetPanicTypeName(panic_id);
      Print("═══════════════════════════════════════");
      Print("[PANIC][", panic_id, "] ", panic_type);
      Print("Message: ", message);
      Print("Time: ", TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS));
      Print("Count: ", m_panic_count);
      Print("═══════════════════════════════════════");
      
      // ========== ファイルに記録 ==========
      WritePanicToFile(panic_id, message);
      
      // ========== 即Flush ==========
      Flush();
   }
   
   //-------------------------------------------------------------------
   //| Flush（Phase 1: 仮実装）                                           |
   //-------------------------------------------------------------------
   virtual void Flush() override
   {
      if(!m_enabled)
         return;
      
      // Phase 1: Printで代用
      Print("[Logger] Flush呼び出し: 件数=", m_count);
      
      // 将来: CSV書き込みなど
   }
   
   //-------------------------------------------------------------------
   //| 統計取得                                                           |
   //-------------------------------------------------------------------
   int GetLogCount() const { return m_count; }
   int GetPanicCount() const { return m_panic_count; }
   
private:
   //-------------------------------------------------------------------
   //| Panicタイプ名取得                                                  |
   //-------------------------------------------------------------------
   string GetPanicTypeName(int panic_id)
   {
      switch(panic_id)
      {
         case PANIC_UNKNOWN:              return "UNKNOWN";
         case PANIC_MEMORY_CORRUPTION:    return "MEMORY_CORRUPTION";
         case PANIC_ORDER_STATE_BROKEN:   return "ORDER_STATE_BROKEN";
         case PANIC_EXECUTION_INCONSIST:  return "EXECUTION_INCONSIST";
         case PANIC_LOGGER_FAILURE:       return "LOGGER_FAILURE";
         case PANIC_INTERNAL_ASSERT:      return "INTERNAL_ASSERT";
         case PANIC_MANUAL_TRIGGER:       return "MANUAL_TRIGGER";
         default:                         return "UNDEFINED";
      }
   }
   
   //-------------------------------------------------------------------
   //| Panicをファイルに記録                                              |
   //-------------------------------------------------------------------
   void WritePanicToFile(int panic_id, const string &message)
   {
      // ファイルオープン（追記モード）
      int handle = FileOpen(m_panic_file, FILE_WRITE | FILE_READ | FILE_TXT | FILE_COMMON);
      
      if(handle == INVALID_HANDLE)
      {
         Print("[Logger] Panicファイルオープン失敗: ", m_panic_file, " エラー=", GetLastError());
         return;
      }
      
      // 末尾に移動
      FileSeek(handle, 0, SEEK_END);
      
      // 記録
      string time_str = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
      string panic_type = GetPanicTypeName(panic_id);
      
      FileWrite(handle, "═══════════════════════════════════════");
      FileWrite(handle, "[PANIC][" + IntegerToString(panic_id) + "] " + panic_type);
      FileWrite(handle, "Time: " + time_str);
      FileWrite(handle, "Message: " + message);
      FileWrite(handle, "Count: " + IntegerToString(m_panic_count));
      FileWrite(handle, "═══════════════════════════════════════");
      FileWrite(handle, "");
      
      FileClose(handle);
   }
};

#endif // CFILELOGGER_MQH
