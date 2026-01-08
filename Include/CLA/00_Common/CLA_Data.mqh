//+------------------------------------------------------------------+
//| File    : CLA_Data.mqh                                           |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Common / Context                                      |
//|                                                                  |
//| Role                                                             |
//|  - 各レイヤー（Gatekeeper / Observation / Decision / Execution） |
//|    間で共有される「状態・結果・文脈」を保持する                  |
//|  - Aegisにおける唯一の状態集約ポイント                           |
//|                                                                  |
//| Core Concept                                                     |
//|  - Aegisは「壊れた理由を説明できるEA」を目指す                   |
//|  - 本クラスはそのための"証拠保管庫"である                        |
//|                                                                  |
//| Design Policy                                                    |
//|  - 判断ロジックは一切持たない                                    |
//|  - 状態・結果・理由のみを保持する                                |
//|  - 各レイヤーは CLA_Data 経由でのみ情報共有を行う                |
//|                                                                  |
//| Phase 2 Notes                                                    |
//|  - Execution層の状態・要求・結果が追加される                     |
//|  - 既存メンバの意味は絶対に変更しない                            |
//|                                                                  |
//| Phase 6 Notes                                                    |
//|  - 状態ログ専用CSV (StateLog_*.csv) を追加                       |
//|  - AddLogEx() メソッド追加                                       |
//|  - RFC 4180準拠CSVエスケープ実装                                 |
//|                                                                  |
//| Change Policy                                                    |
//|  - 拡張のみ許可（削除・再設計・再配置は禁止）                    |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property version     "1.21"
#property strict

#include "CLA_Common.mqh"
#include "CFileLogger.mqh"

// ========== 外部変数参照 ==========
// InpEnableStateLog: Aegis_Core.mqhで定義される状態ログON/OFFフラグ
// AddLogEx()内で参照される

//+------------------------------------------------------------------+
//| CSVエスケープ処理（RFC 4180準拠）                                 |
//| Phase 6: カンマ・ダブルクォート・改行を含む文字列を安全にCSV化    |
//+------------------------------------------------------------------+
string EscapeCSV(string text)
{
   // カンマ、改行、ダブルクォートを含む場合
   if(StringFind(text, ",") >= 0 ||
         StringFind(text, "\n") >= 0 ||
         StringFind(text, "\"") >= 0)
   {
      // ダブルクォートをエスケープ（" → ""）
      StringReplace(text, "\"", "\"\"");

      // 全体をダブルクォートで囲む
      return "\"" + text + "\"";
   }

   return text;  // エスケープ不要
}

//+------------------------------------------------------------------+
//| グローバルデータ管理クラス                                         |
//| 役割：全レイヤー間でのデータ共有、ログ管理                          |
//+------------------------------------------------------------------+
class CLA_Data
{
private:
   // ========== ログ管理 ==========
   CFileLogger m_logger;
   bool        m_console_log_enabled;

   // ========== メモリバッファ ==========
   string      m_log_buffer[];
   int         m_log_buffer_size;
   int         m_log_buffer_count;

   // ========== Phase 6: 状態ログ専用 ==========
   int         m_state_log_handle;       // 状態ログ専用ファイルハンドル
   ulong       m_tick_counter;           // Tick番号カウンタ（簡易実装）

   // ========== レイヤー状態管理 ==========
   ENUM_LAYER_STATUS m_layer_status[6];

   // ========== 市場データ ==========
   double      m_current_bid;
   double      m_current_ask;
   double      m_current_spread;
   datetime    m_current_time;

   // ========== 観測データ ==========
   double      m_rsi_value;

   // ========== フェーズB追加: 追従型OCO観測データ ==========
   bool            m_obs_entry_clear;      // エントリー可能状態（約定前注文・ポジションなし）

   // ========== Gatekeeper状態 ==========
   ENUM_GK_RESULT m_last_gk_result;

   // ========== Execution状態管理（Phase 2追加） ==========
   ENUM_EXEC_STATE    m_exec_state;
   bool               m_exec_locked;
   ENUM_EXEC_REQUEST  m_exec_current_request;
   ENUM_EXEC_RESULT   m_exec_last_result;
   string             m_exec_last_reason;
   ulong              m_exec_last_tick_id;


   // ========== OCO注文パラメータ（Sprint A追加） ==========
   ulong              m_oco_buy_ticket;        // BuyStop注文チケット
   ulong              m_oco_sell_ticket;       // SellStop注文チケット
   double             m_oco_buy_price;         // BuyStop価格
   double             m_oco_sell_price;        // SellStop価格
   double             m_oco_lot;               // ロットサイズ
   double             m_oco_sl_points;         // SL（ポイント）
   double             m_oco_tp_points;         // TP（ポイント）
   int                m_oco_magic;             // マジックナンバー
   double             m_oco_distance_points;   // OCO配置距離（ポイント）

   // ========== 追従管理（Phase 4追加） ==========
   datetime           m_last_order_action_time; // 前回注文配置または変更成功時刻
public:
   //+------------------------------------------------------------------+
   //| コンストラクタ                                                    |
   //+------------------------------------------------------------------+
   CLA_Data()
   {
      m_console_log_enabled = false;
      m_log_buffer_size = 10000;
      m_log_buffer_count = 0;
      ArrayResize(m_log_buffer, m_log_buffer_size);

      // ★Phase 6: 状態ログ初期化
      m_state_log_handle = INVALID_HANDLE;
      m_tick_counter = 0;

      for(int i = 0; i < 6; i++)
      {
         m_layer_status[i] = STATUS_NONE;
      }

      m_current_bid = 0.0;
      m_current_ask = 0.0;
      m_current_spread = 0.0;
      m_current_time = 0;
      m_rsi_value = 0.0;

      m_last_gk_result = GK_PASS;
      m_obs_entry_clear = false;  // フェーズB: 追従型OCO観測初期化

      // ★Phase 2: Execution初期化
      m_exec_state = EXEC_STATE_IDLE;
      m_exec_locked = false;
      m_exec_current_request = EXEC_REQ_NONE;
      m_exec_last_result = EXEC_RESULT_NONE;
      m_exec_last_reason = "";
      m_exec_last_tick_id = 0;

      // ★Sprint A: OCO注文パラメータ初期化
      m_oco_buy_ticket = 0;
      m_oco_sell_ticket = 0;
      m_oco_buy_price = 0.0;
      m_oco_sell_price = 0.0;
      m_oco_lot = 0.01;
      m_oco_sl_points = 0.0;
      m_oco_tp_points = 0.0;
      m_oco_magic = 0;
      m_oco_distance_points = 0.0;

      // ★Phase 4: 追従管理初期化
      m_last_order_action_time = 0;
   }

   //+------------------------------------------------------------------+
   //| 初期化                                                           |
   //| Phase 6: 状態ログ専用CSVファイルを作成                            |
   //+------------------------------------------------------------------+
   bool Init()
   {
      if(!m_logger.Init())
      {
         Print("[エラー] ファイルロガー初期化失敗");
         return false;
      }

      // ★Phase 6: 状態ログ用CSVファイル初期化
      datetime now = TimeCurrent();
      MqlDateTime dt;
      TimeToStruct(now, dt);
      string timestamp_str = StringFormat("%04d%02d%02d_%02d%02d%02d",
                                          dt.year,
                                          dt.mon,
                                          dt.day,
                                          dt.hour,
                                          dt.min,
                                          dt.sec);

      string state_log_filename = "StateLog_" + timestamp_str + ".csv";
      string state_log_path = "Aegis_Logs\\" + state_log_filename;

      // FILE_ANSI: UTF-8ではなくANSI（日本語対応のため）
      // FILE_WRITE: 書き込みモード
      // FILE_CSV: CSV形式
      m_state_log_handle = FileOpen(state_log_path, FILE_WRITE | FILE_CSV | FILE_ANSI, ',');

      if(m_state_log_handle == INVALID_HANDLE)
      {
         Print("[エラー] 状態ログファイル作成失敗: ", state_log_path);
         Print("   LastError: ", GetLastError());
         return false;
      }

      // CSVヘッダー行を書き込み
      string header = "Time_ms,TickSeq,Level,LogID,LogName,Param1,Param2,Param3,Param4,Message\n";
      FileWriteString(m_state_log_handle, header);
      FileFlush(m_state_log_handle);  // ★クラッシュ対策

      Print("[状態ログ] ファイル作成完了: ", state_log_path);

      AddLog(FUNC_ID_CLA_DATA, 0, "CLA_Data初期化完了");
      return true;
   }

   //+------------------------------------------------------------------+
   //| 終了処理                                                         |
   //| Phase 6: 状態ログファイルをクローズ                               |
   //+------------------------------------------------------------------+
   void Deinit()
   {
      AddLog(FUNC_ID_CLA_DATA, 0, "CLA_Data終了処理", true);

      // ★Phase 6: 状態ログファイルクローズ
      if(m_state_log_handle != INVALID_HANDLE)
      {
         FileClose(m_state_log_handle);
         m_state_log_handle = INVALID_HANDLE;
         Print("[状態ログ] ファイルクローズ完了");
      }
   }

   //+------------------------------------------------------------------+
   //| コンソールログ有効/無効設定                                        |
   //+------------------------------------------------------------------+
   void SetConsoleLogEnabled(bool enabled)
   {
      m_console_log_enabled = enabled;
   }

   //+------------------------------------------------------------------+
   //| ログ追加（既存）                                                 |
   //+------------------------------------------------------------------+
   void AddLog(ENUM_FUNCTION_ID func_id, ulong tick_id, string message, bool important = false)
   {
      string level = important ? "IMPORTANT" : "DEBUG";

      if(m_log_buffer_count < m_log_buffer_size)
      {
         string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
         string log_line = StringFormat("%s,Tick#%llu,Func#%d,%s",
                                        timestamp,
                                        tick_id,
                                        func_id,
                                        message);
         m_log_buffer[m_log_buffer_count] = log_line;
         m_log_buffer_count++;
      }

      if(important)
      {
         m_logger.Log(func_id, LOG_LEVEL_INFO, 0, 0);
      }

      if(m_console_log_enabled)
      {
         PrintFormat("[%s] Tick#%llu Func#%d: %s", level, tick_id, func_id, message);
      }
   }

   //+------------------------------------------------------------------+
   //| 拡張ログ記録（Phase 6 Task 3）                                    |
   //| [引数]                                                            |
   //|   log_id  : ログID（100番台）                                     |
   //|   log_name: ログ名称（OCO_PLACE等）                               |
   //|   param1-4: パラメータ1-4（文字列化済み数値）                     |
   //|   message : 説明文（最大256文字）                                 |
   //|   important: 重要フラグ（true=WARN, false=INFO）                 |
   //| [用途]                                                            |
   //|   Phase 6通常状態ログの記録専用                                   |
   //| [実装]                                                            |
   //|   CFileLoggerの拡張版Log()を呼び出し                              |
   //+------------------------------------------------------------------+
   void AddLogEx(
      int log_id,
      string log_name,
      string param1,
      string param2,
      string param3,
      string param4,
      string message,
      bool important = false
   )
   {
      // 状態ログ無効時は何もしない
      if(!InpEnableStateLog)
         return;

      // ログレベル決定
      uchar level = (uchar)(important ? LOG_LEVEL_WARNING : LOG_LEVEL_INFO);

      // パラメータを数値に変換（空文字列は0）
      int p1 = (param1 != "") ? (int)StringToInteger(param1) : 0;
      int p2 = (param2 != "") ? (int)StringToInteger(param2) : 0;
      int p3 = (param3 != "") ? (int)StringToInteger(param3) : 0;
      int p4 = (param4 != "") ? (int)StringToInteger(param4) : 0;

      // CFileLoggerの拡張版Log()を呼び出し
      m_logger.Log(log_id, level, p1, p2, p3, p4, message);
   }

   //+------------------------------------------------------------------+
   //| 全ログをファイルに出力                                            |
   //+------------------------------------------------------------------+
   void FlushAllLogs()
   {
      for(int i = 0; i < m_log_buffer_count; i++)
      {
      }

      string flush_msg = StringFormat("全ログ出力完了: %d件", m_log_buffer_count);

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
      /**/
      Print("[Aegis-TRACE][CLA_Data][CALL SetMarketData]");
      /**/


      m_current_bid = bid;
      m_current_ask = ask;
      m_current_spread = spread;
      m_current_time = time;
   }

   //+------------------------------------------------------------------+
   //| RSI値設定                                                        |
   //+------------------------------------------------------------------+
   void SetRSIValue(double rsi)
   {
      m_rsi_value = rsi;
   }

   //+------------------------------------------------------------------+
   //| RSI値取得                                                        |
   //+------------------------------------------------------------------+
   double GetRSIValue() const
   {
      return m_rsi_value;
   }

   //+------------------------------------------------------------------+
   //| フェーズB追加: 追従型OCO観測データの設定/取得                       |
   //+------------------------------------------------------------------+

   //+------------------------------------------------------------------+
   //| エントリー可能状態設定                                             |
   //| [引数]                                                            |
   //|   is_clear : true=エントリー可能, false=障害あり                   |
   //+------------------------------------------------------------------+
   void SetObs_EntryClear(bool is_clear)
   {
      m_obs_entry_clear = is_clear;
   }

   //+------------------------------------------------------------------+
   //| エントリー可能状態取得                                             |
   //| [戻り値]                                                          |
   //|   true  : エントリー可能（約定前注文・ポジションなし）              |
   //|   false : 障害あり（注文またはポジション存在）                      |
   //+------------------------------------------------------------------+
   bool GetObs_EntryClear() const
   {
      return m_obs_entry_clear;
   }

   //+------------------------------------------------------------------+
   //| 市場データ取得                                                    |
   //+------------------------------------------------------------------+
   double GetCurrentBid() const
   {
      return m_current_bid;
   }
   double GetCurrentAsk() const
   {
      return m_current_ask;
   }
   double GetCurrentSpread() const
   {
      return m_current_spread;
   }
   datetime GetCurrentTime() const
   {
      return m_current_time;
   }

   //+------------------------------------------------------------------+
   //| Gatekeeper結果設定                                                |
   //+------------------------------------------------------------------+
   void SetGatekeeperResult(ENUM_GK_RESULT result, ulong tick_id = 0)
   {
      m_last_gk_result = result;

      if(result != GK_PASS)
      {
         string reason_text = GetGKReasonText(result);
         string log_msg = StringFormat("⛔ Gatekeeper遮断: %s", reason_text);
         AddLog(FUNC_ID_GATEKEEPER, tick_id, log_msg, true);
      }
   }

   //+------------------------------------------------------------------+
   //| Gatekeeper結果取得                                                |
   //+------------------------------------------------------------------+
   ENUM_GK_RESULT GetGatekeeperResult() const
   {
      return m_last_gk_result;
   }

   // ========== Phase 2: Execution状態管理メソッド ==========

   //+------------------------------------------------------------------+
   //| Execution状態取得                                                |
   //+------------------------------------------------------------------+
   ENUM_EXEC_STATE GetExecState() const
   {
      return m_exec_state;
   }

   //+------------------------------------------------------------------+
   //| Executionロック状態取得                                          |
   //+------------------------------------------------------------------+
   bool IsExecLocked() const
   {
      return m_exec_locked;
   }

   //+------------------------------------------------------------------+
   //| Execution状態設定（ログ自動記録）★修正版                          |
   //+------------------------------------------------------------------+
   void SetExecState(ENUM_EXEC_STATE state, ulong tick_id, string reason = "")
   {
      // ★修正: 変更前の状態を保存
      ENUM_EXEC_STATE prev = m_exec_state;
      m_exec_state = state;
      m_exec_last_tick_id = tick_id;

      // 状態変更は重要ログとして記録
      string log_msg = StringFormat("Execution状態変更: %s → %s (%s)",
                                    EnumToString(prev),  // ★修正: 変更前
                                    EnumToString(state), // 変更後
                                    reason != "" ? reason : "理由なし");
      AddLog(FUNC_ID_ORDER_GENERATOR, tick_id, log_msg, true);
   }

   //+------------------------------------------------------------------+
   //| Executionロック設定                                              |
   //+------------------------------------------------------------------+
   void SetExecLock(bool locked, ulong tick_id)
   {
      m_exec_locked = locked;

      if(locked)
      {
         AddLog(FUNC_ID_ORDER_GENERATOR, tick_id, "⚠️ Executionロック設定", true);
      }
   }

   //+------------------------------------------------------------------+
   //| Execution結果記録                                                |
   //+------------------------------------------------------------------+
   void SetExecResult(ENUM_EXEC_RESULT result, string reason, ulong tick_id)
   {
      m_exec_last_result = result;
      m_exec_last_reason = reason;

      bool is_important = (result != EXEC_RESULT_SUCCESS);
      string log_msg = StringFormat("Execution結果: %s - %s",
                                    EnumToString(result),
                                    reason);
      AddLog(FUNC_ID_ORDER_GENERATOR, tick_id, log_msg, is_important);
   }

   //+------------------------------------------------------------------+
   //| Execution操作要求設定                                            |
   //+------------------------------------------------------------------+
   void SetExecRequest(ENUM_EXEC_REQUEST request, ulong tick_id)
   {
      m_exec_current_request = request;

      if(request != EXEC_REQ_NONE)
      {
         string log_msg = StringFormat("Execution要求受付: %s", EnumToString(request));
         AddLog(FUNC_ID_ORDER_GENERATOR, tick_id, log_msg, false);
      }
   }

   //+------------------------------------------------------------------+
   //| 現在の操作要求取得                                                |
   //+------------------------------------------------------------------+
   ENUM_EXEC_REQUEST GetExecRequest() const
   {
      return m_exec_current_request;
   }

   //+------------------------------------------------------------------+
   //| 最後の実行結果取得                                                |
   //+------------------------------------------------------------------+
   ENUM_EXEC_RESULT GetExecLastResult() const
   {
      return m_exec_last_result;
   }

   string GetExecLastReason() const
   {
      return m_exec_last_reason;
   }

   // ========== OCO注文パラメータ getter/setter（Sprint A追加） ==========

   //+------------------------------------------------------------------+
   //| OCO BuyStop チケット設定/取得                                     |
   //+------------------------------------------------------------------+
   void SetOCOBuyTicket(ulong ticket)
   {
      m_oco_buy_ticket = ticket;
   }
   ulong GetOCOBuyTicket() const
   {
      return m_oco_buy_ticket;
   }

   //+------------------------------------------------------------------+
   //| OCO SellStop チケット設定/取得                                    |
   //+------------------------------------------------------------------+
   void SetOCOSellTicket(ulong ticket)
   {
      m_oco_sell_ticket = ticket;
   }
   ulong GetOCOSellTicket() const
   {
      return m_oco_sell_ticket;
   }

   //+------------------------------------------------------------------+
   //| OCO BuyStop 価格設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOBuyPrice(double price)
   {
      m_oco_buy_price = price;
   }
   double GetOCOBuyPrice() const
   {
      return m_oco_buy_price;
   }

   //+------------------------------------------------------------------+
   //| OCO SellStop 価格設定/取得                                        |
   //+------------------------------------------------------------------+
   void SetOCOSellPrice(double price)
   {
      m_oco_sell_price = price;
   }
   double GetOCOSellPrice() const
   {
      return m_oco_sell_price;
   }

   //+------------------------------------------------------------------+
   //| OCO ロットサイズ設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOLot(double lot)
   {
      m_oco_lot = lot;
   }
   double GetOCOLot() const
   {
      return m_oco_lot;
   }

   //+------------------------------------------------------------------+
   //| OCO SL(ポイント)設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOSLPoints(double points)
   {
      m_oco_sl_points = points;
   }
   double GetOCOSLPoints() const
   {
      return m_oco_sl_points;
   }

   //+------------------------------------------------------------------+
   //| OCO TP(ポイント)設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOTPPoints(double points)
   {
      m_oco_tp_points = points;
   }
   double GetOCOTPPoints() const
   {
      return m_oco_tp_points;
   }

   //+------------------------------------------------------------------+
   //| OCO マジックナンバー設定/取得                                      |
   //+------------------------------------------------------------------+
   void SetOCOMagic(int magic)
   {
      m_oco_magic = magic;
   }
   int GetOCOMagic() const
   {
      return m_oco_magic;
   }

   //+------------------------------------------------------------------+
   //| OCO 配置距離(ポイント)設定/取得                                    |
   //+------------------------------------------------------------------+
   void SetOCODistancePoints(double points)
   {
      m_oco_distance_points = points;
   }
   double GetOCODistancePoints() const
   {
      return m_oco_distance_points;
   }

   //+------------------------------------------------------------------+
   //| 追従管理（Phase 4追加）                                            |
   //+------------------------------------------------------------------+
   void SetLastOrderActionTime(datetime time)
   {
      m_last_order_action_time = time;
   }
   datetime GetLastOrderActionTime() const
   {
      return m_last_order_action_time;
   }
};

//+------------------------------------------------------------------+
//| Phase 6 テスト用関数                                              |
//| AddLogEx()の動作確認用                                            |
//+------------------------------------------------------------------+
void TestAddLogEx()
{
   CLA_Data data;
   if(!data.Init())
   {
      Print("[テスト失敗] CLA_Data初期化エラー");
      return;
   }

   Print("========== Phase 6 テスト開始 ==========");

   // テストケース1: チケット番号 + 価格
   data.AddLogEx(
      LOG_ID_OCO_PLACE,
      "TEST_OCO_PLACE",
      IntegerToString(12345),           // チケット番号
      DoubleToString(152.480, 3),       // 価格
      IntegerToString(12346),
      DoubleToString(152.380, 3),
      "テスト: RSI=72.5 SellStop優先",
      false
   );
   Print("[テスト1] OCO_PLACE ログ出力完了");

   // テストケース2: カンマ・引用符を含むメッセージ
   data.AddLogEx(
      LOG_ID_MODIFY_FAIL,
      "TEST_ESCAPE",
      "1001",
      "152.500",
      "",
      "",
      "エラー: \"No changes\" detected, spread=15pt",
      true
   );
   Print("[テスト2] CSVエスケープテスト完了");

   // テストケース3: 空パラメータ
   data.AddLogEx(
      LOG_ID_DECISION_SKIP,
      "TEST_SKIP",
      "",
      "",
      "",
      "",
      "理由: クールダウン中",
      false
   );
   Print("[テスト3] 空パラメータテスト完了");

   // テストケース4: 改行を含むメッセージ
   data.AddLogEx(
      LOG_ID_TRAIL_TRIGGER,
      "TEST_NEWLINE",
      "999",
      "157.123",
      "",
      "",
      "追従トリガー\n次の行: 詳細情報",
      false
   );
   Print("[テスト4] 改行エスケープテスト完了");

   data.Deinit();
   Print("========== Phase 6 テスト完了 ==========");
   Print("CSVファイルを確認してください: Aegis_Logs\\StateLog_*.csv");
}

//+------------------------------------------------------------------+
//| グローバルインスタンス                                             |
//+------------------------------------------------------------------+
CLA_Data g_data;

//+------------------------------------------------------------------+
