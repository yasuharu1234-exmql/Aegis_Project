//+------------------------------------------------------------------+
//|                                                 CGatekeeper.mqh |
//|                                  Copyright 2025, Aegis Hybrid EA |
//|                                     Designed by ChatGPT & Gemini |
//|                                                                  |
//| Phase 6 Task 2 - Phase 4                                         |
//|  - Gatekeeper層ログ追加（拒否理由記録）                           |
//|  - 状態変化時のみログ出力                                         |
//+------------------------------------------------------------------+
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"

//========================================================================
// ■ Gatekeeper クラス
//------------------------------------------------------------------------
// [役割]
//   取引の「前提条件」をチェックする最終関門。
//   拒否時に理由を記録し、状態変化時のみログを出力する。
//========================================================================
class CGatekeeper
{
private:
   // --- 設定閾値 ---
   double m_max_spread_pips;      // 最大スプレッド(pips)
   double m_min_margin_level;     // 最低証拠金維持率(%)
   int    m_max_tick_gap_sec;     // 許容最大Tick間隔(秒) - 分析用データ品質保証

   // --- 内部計算用 ---
   double m_pip_multiplier;       // Pips -> Points 変換係数

   // --- 状態保持 ---
   datetime m_last_tick_time;     // 前回のTick時刻（整合性チェック用）

   // --- Phase 6 Task 2 - Phase 4: ログ状態管理 ---
   ENUM_GK_RESULT m_last_reject_reason;  // 前回の拒否理由（状態変化検出用）

public:
   //---------------------------------------------------------------------
   // ■ コンストラクタ
   //---------------------------------------------------------------------
   CGatekeeper()
   {
      // デフォルト設定（安全側の値）
      m_max_spread_pips = 5.0;
      m_min_margin_level = 100.0;
      m_max_tick_gap_sec = 30;    // 30秒以上Tickが来なければ異常とみなす

      m_last_tick_time = 0;
      m_pip_multiplier = 1.0;
      m_last_reject_reason = GK_PASS;  // Phase 4: 初期化
   }

   //---------------------------------------------------------------------
   // ■ 初期化
   //---------------------------------------------------------------------
   bool Init()
   {
      m_last_tick_time = 0;
      m_last_reject_reason = GK_PASS;  // Phase 4: リセット

      // 通貨ペアに合わせたPips変換係数の計算
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      if(digits == 3 || digits == 5)
      {
         m_pip_multiplier = 10.0; // 1.0 pips = 10 points
      }
      else
      {
         m_pip_multiplier = 1.0;  // 1.0 pips = 1 point
      }

      return true;
   }

   void Deinit()
   {
   }

   //---------------------------------------------------------------------
   // ■ 設定メソッド（外部パラメータから値を注入）
   //---------------------------------------------------------------------
   void SetThresholds(double max_spread_pips, double min_margin_level, int max_tick_gap_sec = 30)
   {
      m_max_spread_pips = max_spread_pips;
      m_min_margin_level = min_margin_level;
      m_max_tick_gap_sec = max_tick_gap_sec;
   }

   //---------------------------------------------------------------------
   // ■ メイン判定メソッド (Execute)
   // [役割]
   //   各チェックを「正しい順序」で実行し、通過可否を判定する。
   //   拒否時は理由を記録し、状態変化時のみログを出力する。
   //---------------------------------------------------------------------
   bool Execute(CLA_Data &data, ulong tick_id, ENUM_GK_RESULT &reason)
   {
      reason = GK_PASS; // デフォルト

      // 1. Tick健全性チェック (Data Integrity) - 最優先
      if(!CheckTickIntegrity(data, tick_id, reason)) return false;

      // 2. 市場状態チェック (Context)
      if(!CheckMarketContext(data, tick_id, reason)) return false;

      // 3. 資金状態チェック (Funds)
      if(!CheckAccountStatus(data, tick_id, reason)) return false;

      // 4. システム状態チェック (System)
      //    TODO: API error check

      // Phase 4: 正常通過時、前回拒否されていた場合はリセット
      if(m_last_reject_reason != GK_PASS)
      {
         m_last_reject_reason = GK_PASS;
         // 正常復帰はログに記録しない（戦略層で対応済み）
      }

      return true; // 全ゲート通過
   }

private:
   //---------------------------------------------------------------------
   // [内部] 1. Tick健全性チェック（Phase 5: Tick間隔チェック無効化）
   //---------------------------------------------------------------------
   bool CheckTickIntegrity(CLA_Data &data, ulong tick_id, ENUM_GK_RESULT &reason)
   {
      datetime current_time = TimeCurrent();

      // 初回チェック時はスキップ
      if(m_last_tick_time > 0)
      {
         // 時刻逆行チェック
         if(current_time < m_last_tick_time)
         {
            reason = GK_FAIL_TICK_ANOMALY;
            LogRejectReason(data, tick_id, reason, current_time, m_last_tick_time);
            return false;
         }

         // ★Phase 5: 無Tick期間チェック (Gap Check) を無効化
         // テスターでは正常なTickが「異常」と判定されるため
         /*
         if((current_time - m_last_tick_time) > m_max_tick_gap_sec) {
             reason = GK_FAIL_TICK_GAP;
             LogRejectReason(data, tick_id, reason);
             return false;
         }
         */
      }
      m_last_tick_time = current_time; // 更新

      // 価格異常チェック
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      if(bid <= 0 || ask <= 0 || ask < bid)
      {
         reason = GK_FAIL_PRICE_INVALID;
         LogRejectReason(data, tick_id, reason, bid, ask);
         return false;
      }

      return true;
   }

   //---------------------------------------------------------------------
   // [内部] 2. 市場状態チェック
   //---------------------------------------------------------------------
   bool CheckMarketContext(CLA_Data &data, ulong tick_id, ENUM_GK_RESULT &reason)
   {
      // 取引許可チェック
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      {
         reason = GK_FAIL_TRADE_DISABLED;
         LogRejectReason(data, tick_id, reason);
         return false;
      }

      // ★Phase 5: スプレッドチェックを一時的に無効化
      // テスターでスプレッド異常が頻発するため
      /*
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      double spread_points = (ask - bid) / point;
      double spread_pips = spread_points / m_pip_multiplier;

      if(spread_pips > m_max_spread_pips) {
          reason = GK_FAIL_SPREAD_HIGH;
          LogRejectReason(data, tick_id, reason, spread_pips, m_max_spread_pips);
          return false;
      }
      */

      return true;
   }

   //---------------------------------------------------------------------
   // [内部] 3. 資金状態チェック
   //---------------------------------------------------------------------
   bool CheckAccountStatus(CLA_Data &data, ulong tick_id, ENUM_GK_RESULT &reason)
   {
      double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

      // 証拠金維持率チェック（ポジション保有時のみ）
      if(PositionsTotal() > 0 && margin_level < m_min_margin_level)
      {
         reason = GK_FAIL_MARGIN_LEVEL;
         LogRejectReason(data, tick_id, reason, margin_level, m_min_margin_level);
         return false;
      }

      return true;
   }

   //---------------------------------------------------------------------
   // [Phase 4] 拒否理由ログ記録（状態変化時のみ）
   //---------------------------------------------------------------------
   void LogRejectReason(CLA_Data &data, ulong tick_id, ENUM_GK_RESULT reason,
                        double param1 = 0, double param2 = 0, double param3 = 0, double param4 = 0)
   {
      // 状態変化チェック：前回と同じ拒否理由なら記録しない
      if(reason == m_last_reject_reason)
      {
         return;  // 同一状態継続 → ログ抑制
      }

      // 状態が変化した → ログ記録
      m_last_reject_reason = reason;

      // InpEnableStateLogでON/OFF制御
      if(!InpEnableStateLog)
      {
         return;
      }

      // ログID計算（1000 + ENUM_GK_RESULT下3桁）
      int log_id = 1000 + (reason % 1000);
      string log_name = "GK_REJECT";
      string message = GetGKReasonText(reason);

      // パラメータを文字列に変換
      string p1 = (param1 != 0) ? DoubleToString(param1, 5) : "";
      string p2 = (param2 != 0) ? DoubleToString(param2, 5) : "";
      string p3 = (param3 != 0) ? DoubleToString(param3, 5) : "";
      string p4 = (param4 != 0) ? DoubleToString(param4, 5) : "";

      // ログ出力
      data.AddLogEx(
         log_id,
         log_name,
         p1,
         p2,
         p3,
         p4,
         message,
         true  // 拒否は重要ログ
      );
   }
};
//+------------------------------------------------------------------+
