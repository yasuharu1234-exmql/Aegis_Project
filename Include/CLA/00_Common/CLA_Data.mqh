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
//|  - 本クラスはそのための“証拠保管庫”である                        |
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
//| Change Policy                                                    |
//|  - 拡張のみ許可（削除・再設計・再配置は禁止）                    |
//|                                                                  |
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
   CFileLogger m_logger;
   bool        m_console_log_enabled;
   
   // ========== メモリバッファ ==========
   string      m_log_buffer[];
   int         m_log_buffer_size;
   int         m_log_buffer_count;
   
   // ========== レイヤー状態管理 ==========
   ENUM_LAYER_STATUS m_layer_status[6];
   
   // ========== 市場データ ==========
   double      m_current_bid;
   double      m_current_ask;
   double      m_current_spread;
   datetime    m_current_time;
   
   // ========== 観測データ ==========
   double      m_rsi_value;
   
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
   }
   
   //+------------------------------------------------------------------+
   //| コンソールログ有効/無効設定                                        |
   //+------------------------------------------------------------------+
   void SetConsoleLogEnabled(bool enabled)
   {
      m_console_log_enabled = enabled;
   }
   
   //+------------------------------------------------------------------+
   //| ログ追加                                                         |
   //+------------------------------------------------------------------+
   void AddLog(ENUM_FUNCTION_ID func_id, ulong tick_id, string message, bool important = false)
   {
      string level = important ? "IMPORTANT" : "DEBUG";
      
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
   void SetOCOBuyTicket(ulong ticket) { m_oco_buy_ticket = ticket; }
   ulong GetOCOBuyTicket() const { return m_oco_buy_ticket; }
   
   //+------------------------------------------------------------------+
   //| OCO SellStop チケット設定/取得                                    |
   //+------------------------------------------------------------------+
   void SetOCOSellTicket(ulong ticket) { m_oco_sell_ticket = ticket; }
   ulong GetOCOSellTicket() const { return m_oco_sell_ticket; }
   
   //+------------------------------------------------------------------+
   //| OCO BuyStop 価格設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOBuyPrice(double price) { m_oco_buy_price = price; }
   double GetOCOBuyPrice() const { return m_oco_buy_price; }
   
   //+------------------------------------------------------------------+
   //| OCO SellStop 価格設定/取得                                        |
   //+------------------------------------------------------------------+
   void SetOCOSellPrice(double price) { m_oco_sell_price = price; }
   double GetOCOSellPrice() const { return m_oco_sell_price; }
   
   //+------------------------------------------------------------------+
   //| OCO ロットサイズ設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOLot(double lot) { m_oco_lot = lot; }
   double GetOCOLot() const { return m_oco_lot; }
   
   //+------------------------------------------------------------------+
   //| OCO SL(ポイント)設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOSLPoints(double points) { m_oco_sl_points = points; }
   double GetOCOSLPoints() const { return m_oco_sl_points; }
   
   //+------------------------------------------------------------------+
   //| OCO TP(ポイント)設定/取得                                         |
   //+------------------------------------------------------------------+
   void SetOCOTPPoints(double points) { m_oco_tp_points = points; }
   double GetOCOTPPoints() const { return m_oco_tp_points; }
   
   //+------------------------------------------------------------------+
   //| OCO マジックナンバー設定/取得                                      |
   //+------------------------------------------------------------------+
   void SetOCOMagic(int magic) { m_oco_magic = magic; }
   int GetOCOMagic() const { return m_oco_magic; }
   
   //+------------------------------------------------------------------+
   //| OCO 配置距離(ポイント)設定/取得                                    |
   //+------------------------------------------------------------------+
   void SetOCODistancePoints(double points) { m_oco_distance_points = points; }
   double GetOCODistancePoints() const { return m_oco_distance_points; }
   
   //+------------------------------------------------------------------+
   //| 追従管理（Phase 4追加）                                            |
   //+------------------------------------------------------------------+
   void SetLastOrderActionTime(datetime time) { m_last_order_action_time = time; }
   datetime GetLastOrderActionTime() const { return m_last_order_action_time; }
};

//+------------------------------------------------------------------+
//| グローバルインスタンス                                             |
//+------------------------------------------------------------------+
CLA_Data g_data;

//+------------------------------------------------------------------+
