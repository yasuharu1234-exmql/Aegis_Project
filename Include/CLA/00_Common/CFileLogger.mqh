//+------------------------------------------------------------------+
//|                                              CFileLogger.mqh     |
//|                                  Copyright 2025, Aegis Project   |
//|                          https://github.com/YasuharuEA/Aegis     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Aegis Project"
#property link        "https://github.com/YasuharuEA/Aegis"
#property strict

//+------------------------------------------------------------------+
//| ファイルロガークラス（UTF-8 BOM付き版）                            |
//|                                                                  |
//| [概要]                                                            |
//|   ログメッセージをUTF-8（BOM付き）CSVファイルに書き込む。           |
//|   日次でファイルを分割し、確実にディスクに保存する。                  |
//|                                                                  |
//| [設計思想]                                                         |
//|   - 信頼性優先：都度オープン・クローズでデータ損失を防ぐ              |
//|   - AI親和性：UTF-8でClaude/Geminiが直接読める                     |
//|   - 可読性：CSV形式、BOM付きでExcelも対応                          |
//|   - 保守性：日次分割で巨大ファイル化を防ぐ                           |
//|   - MT4/MT5両対応：標準ファイル関数を使用                           |
//|                                                                  |
//| [ファイル形式]                                                     |
//|   日時,TickID,機能ID,ログレベル,メッセージ                          |
//|   2025.12.20 09:15:30,12345,FUNC_ID_PRICE_OBSERVER,INFO,価格更新  |
//+------------------------------------------------------------------+
class CFileLogger
{
private:
   //--- メンバ変数
   string m_base_folder;      // ベースフォルダ（"Aegis\\Logs\\"）
   string m_current_date;     // 現在の日付（yyyyMMdd）
   bool   m_initialized;      // 初期化済みフラグ
   bool   m_header_written;   // ヘッダー書き込み済みフラグ
   
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CFileLogger()
   {
      m_base_folder = "Aegis\\Logs\\";
      m_current_date = "";
      m_initialized = false;
      m_header_written = false;
   }
   
   //-------------------------------------------------------------------
   //| デストラクタ                                                       |
   //-------------------------------------------------------------------
   ~CFileLogger()
   {
      // 都度クローズのため特に処理なし
   }
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   bool Init()
   {
      // フォルダ作成（存在しなければ作成）
      if(!CreateDirectory())
      {
         Print("[FileLogger] エラー: ログディレクトリの作成に失敗しました");
         return false;
      }
      
      m_initialized = true;
      Print("[FileLogger] 初期化成功 (保存先: ", m_base_folder, ", エンコーディング: UTF-8 BOM)");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| ログ書き込みメソッド                                                |
   //| [引数]                                                            |
   //|   func_id : 機能ID                                               |
   //|   tick_id : TickユニークID                                       |
   //|   message : ログメッセージ                                         |
   //|   level   : ログレベル（デフォルト="INFO"）                         |
   //-------------------------------------------------------------------
   bool WriteLog(ENUM_FUNCTION_ID func_id, ulong tick_id, string message, string level = "INFO")
   {
      if(!m_initialized)
      {
         Print("[FileLogger] エラー: 初期化されていません");
         return false;
      }
      
      // 日付が変わったかチェック
      string today = GetTodayString();
      if(today != m_current_date)
      {
         m_current_date = today;
         m_header_written = false; // 新しいファイルなのでヘッダー未書き込み
      }
      
      // ファイル名生成
      string filename = m_base_folder + "Aegis_Log_" + m_current_date + ".csv";
      
      // ファイルを開く（UTF-8 BOM付き）
      // FILE_UNICODE = UTF-16LE（内部）→ UTF-8 BOM（ファイル）に自動変換
      // FILE_COMMON = 共通フォルダに保存（全ターミナルで共有）
      int handle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_CSV | FILE_UNICODE | FILE_COMMON, ',');
      
      if(handle == INVALID_HANDLE)
      {
         int error = GetLastError();
         PrintFormat("[FileLogger] エラー: ファイルオープン失敗 (%s), Error: %d", 
            filename, error);
         PrintFormat("[FileLogger] デバッグ: 保存先フルパス確認 = MQL4/Files/%s または MQL5/Files/%s", 
            filename, filename);
         return false;
      }
      else
      {
         // 初回のみ成功メッセージ（毎回は出さない）
         static bool first_write = true;
         if(first_write)
         {
            PrintFormat("[FileLogger] ✅ ファイルオープン成功: %s", filename);
            first_write = false;
         }
      }
      
      // ファイルの末尾に移動
      FileSeek(handle, 0, SEEK_END);
      
      // ヘッダー書き込み（ファイルが空の場合）
      if(FileSize(handle) == 0 || !m_header_written)
      {
         FileWrite(handle, "日時", "TickID", "機能ID", "ログレベル", "メッセージ");
         m_header_written = true;
      }
      
      // ログレコード書き込み
      string datetime_str = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
      string func_id_str = EnumToString(func_id);
      
      // CSVエスケープ処理（カンマやダブルクォートを含む場合）
      string escaped_message = EscapeCSV(message);
      
      FileWrite(handle, datetime_str, IntegerToString(tick_id), func_id_str, level, escaped_message);
      
      // ファイルを閉じる（即座にフラッシュ）
      FileClose(handle);
      
      return true;
   }
   
private:
   //-------------------------------------------------------------------
   //| ディレクトリ作成                                                   |
   //-------------------------------------------------------------------
   bool CreateDirectory()
   {
      // "Aegis" フォルダ作成
      FolderCreate("Aegis", FILE_COMMON);
      
      // "Aegis\\Logs" フォルダ作成
      FolderCreate("Aegis\\Logs", FILE_COMMON);
      
      // エラーチェックは省略（既存フォルダでもエラーになるため）
      ResetLastError();
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 今日の日付を"yyyyMMdd"形式で取得                                   |
   //-------------------------------------------------------------------
   string GetTodayString()
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      return StringFormat("%04d%02d%02d", dt.year, dt.mon, dt.day);
   }
   
   //-------------------------------------------------------------------
   //| CSVエスケープ処理                                                  |
   //| [引数]                                                            |
   //|   text : エスケープ対象のテキスト                                   |
   //| [戻り値]                                                          |
   //|   エスケープ済みテキスト                                            |
   //-------------------------------------------------------------------
   string EscapeCSV(string text)
   {
      // カンマ、ダブルクォート、改行を含む場合はダブルクォートで囲む
      if(StringFind(text, ",") >= 0 || 
         StringFind(text, "\"") >= 0 || 
         StringFind(text, "\n") >= 0)
      {
         // ダブルクォートを2つにエスケープ
         StringReplace(text, "\"", "\"\"");
         
         // 全体をダブルクォートで囲む
         text = "\"" + text + "\"";
      }
      
      return text;
   }
};

//+------------------------------------------------------------------+
//| End of CFileLogger.mqh                                           |
//+------------------------------------------------------------------+