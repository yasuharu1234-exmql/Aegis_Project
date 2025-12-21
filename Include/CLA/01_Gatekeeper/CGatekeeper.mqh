//+------------------------------------------------------------------+
//|                                                 CGatekeeper.mqh |
//|                                  Copyright 2025, Aegis Hybrid EA |
//|                                     Designed by ChatGPT & Gemini |
//+------------------------------------------------------------------+
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"

//========================================================================
// ■ Gatekeeper クラス
//------------------------------------------------------------------------
// [役割]
//   取引の「前提条件」をチェックする最終関門。
//   ログ出力は行わず、理由コード(reason)を返すことに徹する。
//========================================================================
class CGatekeeper {
private:
   // --- 設定閾値 ---
   double m_max_spread_pips;      // 最大スプレッド(pips)
   double m_min_margin_level;     // 最低証拠金維持率(%)
   int    m_max_tick_gap_sec;     // 許容最大Tick間隔(秒) - 分析用データ品質保証
   
   // --- 内部計算用 ---
   double m_pip_multiplier;       // Pips -> Points 変換係数
   
   // --- 状態保持 ---
   datetime m_last_tick_time;     // 前回のTick時刻（整合性チェック用）
   
public:
   //---------------------------------------------------------------------
   // ■ コンストラクタ
   //---------------------------------------------------------------------
   CGatekeeper() {
      // デフォルト設定（安全側の値）
      m_max_spread_pips = 5.0;
      m_min_margin_level = 100.0; 
      m_max_tick_gap_sec = 30;    // 30秒以上Tickが来なければ異常とみなす
      
      m_last_tick_time = 0;
      m_pip_multiplier = 1.0;
   }
   
   //---------------------------------------------------------------------
   // ■ 初期化
   //---------------------------------------------------------------------
   bool Init() {
      m_last_tick_time = 0;
      
      // 通貨ペアに合わせたPips変換係数の計算
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      if(digits == 3 || digits == 5) {
         m_pip_multiplier = 10.0; // 1.0 pips = 10 points
      } else {
         m_pip_multiplier = 1.0;  // 1.0 pips = 1 point
      }
      
      return true;
   }
   
   void Deinit() {
   }
   
   //---------------------------------------------------------------------
   // ■ 設定メソッド（外部パラメータから値を注入）
   //---------------------------------------------------------------------
   void SetThresholds(double max_spread_pips, double min_margin_level, int max_tick_gap_sec = 30) {
      m_max_spread_pips = max_spread_pips;
      m_min_margin_level = min_margin_level;
      m_max_tick_gap_sec = max_tick_gap_sec;
   }

   //---------------------------------------------------------------------
   // ■ メイン判定メソッド (Execute)
   // [役割]
   //   各チェックを「正しい順序」で実行し、通過可否を判定する。
   //   ログ出力は行わず、理由コード(reason)を返すことに徹する。
   //---------------------------------------------------------------------
   bool Execute(CLA_Data &data, ulong tick_id, ENUM_GK_RESULT &reason) {
      reason = GK_PASS; // デフォルト

      // 1. Tick健全性チェック (Data Integrity) - 最優先
      if(!CheckTickIntegrity(tick_id, reason)) return false;

      // 2. 市場状態チェック (Context)
      if(!CheckMarketContext(reason)) return false;
      
      // 3. 資金状態チェック (Funds)
      if(!CheckAccountStatus(reason)) return false;

      // 4. システム状態チェック (System)
      //    TODO: API error check

      return true; // 全ゲート通過
   }

private:
   //---------------------------------------------------------------------
   // [内部] 1. Tick健全性チェック
   //---------------------------------------------------------------------
   bool CheckTickIntegrity(ulong tick_id, ENUM_GK_RESULT &reason) {
       datetime current_time = TimeCurrent();
       
       // 初回チェック時はスキップ
       if(m_last_tick_time > 0) {
           // 時刻逆行チェック
           if(current_time < m_last_tick_time) {
               reason = GK_FAIL_TICK_ANOMALY;
               return false;
           }
           
           // 無Tick期間チェック (Gap Check)
           if((current_time - m_last_tick_time) > m_max_tick_gap_sec) {
               reason = GK_FAIL_TICK_GAP;
               return false;
           }
       }
       m_last_tick_time = current_time; // 更新

       // 価格異常チェック
       double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
       double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
       
       if(bid <= 0 || ask <= 0 || ask < bid) {
           reason = GK_FAIL_PRICE_INVALID;
           return false;
       }
       
       return true;
   }

   //---------------------------------------------------------------------
   // [内部] 2. 市場状態チェック
   //---------------------------------------------------------------------
   bool CheckMarketContext(ENUM_GK_RESULT &reason) {
       // 取引許可チェック
       if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
           reason = GK_FAIL_TRADE_DISABLED;
           return false;
       }
       
       // スプレッドチェック
       long spread_points = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
       double threshold_points = m_max_spread_pips * m_pip_multiplier;
       
       if(spread_points > threshold_points) {
            reason = GK_FAIL_SPREAD_HIGH;
            return false;
       }
       
       return true;
   }

   //---------------------------------------------------------------------
   // [内部] 3. 資金状態チェック
   //---------------------------------------------------------------------
   bool CheckAccountStatus(ENUM_GK_RESULT &reason) {
       // 余剰証拠金チェック
       double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
       if(free_margin <= 0) {
           reason = GK_FAIL_MARGIN_LOW;
           return false;
       }
       
       // 証拠金維持率チェック
       double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
       if(margin_level > 0 && margin_level < m_min_margin_level) {
           reason = GK_FAIL_MARGIN_LEVEL;
           return false;
       }
       
       return true;
   }
};