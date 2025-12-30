//+------------------------------------------------------------------+
//|                                      CDecisionRSI_Simple.mqh     |
//|                                  Copyright 2025, Aegis Project   |
//|                          https://github.com/YasuharuEA/Aegis     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Aegis Project"
#property link        "https://github.com/YasuharuEA/Aegis"
#property strict

//+------------------------------------------------------------------+
//| インクルード                                                        |
//+------------------------------------------------------------------+
#include "CDecisionBase.mqh"
#include "../02_Observation/CObservationRSI.mqh"

//+------------------------------------------------------------------+
//| RSIシンプル判断クラス                                               |
//|                                                                  |
//| [概要]                                                            |
//|   RSIの値を基に、シンプルな逆張りロジックで売買判断を行う。           |
//|   - RSI < 30 → 買いシグナル（売られすぎ）                           |
//|   - RSI > 70 → 売りシグナル（買われすぎ）                           |
//|   - それ以外 → 待機                                                |
//|                                                                  |
//| [設計思想]                                                         |
//|   - 最もシンプルな判断ロジックの実装例                                |
//|   - Layer 2（CObservationRSI）への依存を明示                        |
//|   - 判断理由を必ずログに残す                                         |
//|                                                                  |
//| [使用例]                                                          |
//|   CObservationRSI rsi_observer(14);                              |
//|   CDecisionRSI_Simple decision(&rsi_observer);                   |
//|   decision.Init();                                               |
//|   decision.Update(g_data, tick_id);                              |
//+------------------------------------------------------------------+
class CDecisionRSI_Simple : public CDecisionBase
{
private:
   //--- メンバ変数
   CObservationRSI* m_rsi_observer;  // RSI観測クラスへのポインタ
   double           m_oversold;      // 売られすぎ閾値
   double           m_overbought;    // 買われすぎ閾値
   
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //| [引数]                                                            |
   //|   rsi_observer : RSI観測クラスのポインタ（Layer 2との連携）         |
   //|   oversold     : 売られすぎ閾値（デフォルト30）                      |
   //|   overbought   : 買われすぎ閾値（デフォルト70）                      |
   //|   priority     : 優先度（デフォルト100）                            |
   //-------------------------------------------------------------------
   CDecisionRSI_Simple(
      CObservationRSI* rsi_observer,
      double oversold = 30.0,
      double overbought = 70.0,
      int priority = 100
   ) : CDecisionBase(FUNC_ID_LOGIC_RSI_SIMPLE, priority)
   {
      m_rsi_observer = rsi_observer;
      m_oversold = oversold;
      m_overbought = overbought;
   }
   
   //-------------------------------------------------------------------
   //| デストラクタ                                                       |
   //-------------------------------------------------------------------
   ~CDecisionRSI_Simple()
   {
      // ポインタは削除しない（所有権はメインEAにある）
   }
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      // 親クラスの初期化を呼び出す
      if(!CDecisionBase::Init())
      {
         Print("[RSI判断] 初期化失敗");
         return false;
      }
      
      // RSI観測クラスが正しく渡されているか確認
      if(m_rsi_observer == NULL)
      {
         Print("[RSI判断] エラー: RSI観測クラスが指定されていません");
         return false;
      }
      
      if(!m_rsi_observer.IsInitialized())
      {
         Print("[RSI判断] エラー: RSI観測クラスが初期化されていません");
         return false;
      }
      
      PrintFormat("[RSI判断] 初期化成功 (売られすぎ: %.1f, 買われすぎ: %.1f)",
         m_oversold, m_overbought);
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[RSI判断] 終了処理");
      CDecisionBase::Deinit();
   }
   
   //-------------------------------------------------------------------
   //| 更新メソッド（判断ロジックの実装）                                   |
   //| [引数]                                                            |
   //|   data    : システム共通データ（参照渡し）                            |
   //|   tick_id : この操作のユニークID                                    |
   //| [戻り値]                                                          |
   //|   true  : 更新成功                                                |
   //|   false : 更新失敗                                                |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // RSI観測クラスから最新値を取得
      double rsi_value = m_rsi_observer.GetLastValue();
      
      // 現在の価格を取得（記録用）
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      // シグナル判定
      ENUM_SIGNAL_TYPE signal = SIGNAL_NONE;
      double strength = 0.0;
      string reason = "";
      
      if(rsi_value < m_oversold)
      {
         // 売られすぎ → 買いシグナル
         signal = SIGNAL_BUY;
         strength = (m_oversold - rsi_value) / m_oversold;  // 確信度を計算
         reason = StringFormat("RSI: %.1f → 買いシグナル発生！（売られすぎ）", rsi_value);
      }
      else if(rsi_value > m_overbought)
      {
         // 買われすぎ → 売りシグナル
         signal = SIGNAL_SELL;
         strength = (rsi_value - m_overbought) / (100.0 - m_overbought);  // 確信度を計算
         reason = StringFormat("RSI: %.1f → 売りシグナル発生！（買われすぎ）", rsi_value);
      }
      else
      {
         // 中立 → 待機
         signal = SIGNAL_NONE;
         strength = 0.0;
         reason = StringFormat("RSI: %.1f → 待機中（中立ゾーン）", rsi_value);
      }
      
      // 判断結果を保存
      SetSignal(signal, strength, current_price);
      
      // ログ記録（シグナル発生時は強調）
      if(signal != SIGNAL_NONE)
      {
         // シグナル発生時は目立つログ
         data.AddLog(FUNC_ID_LOGIC_RSI_SIMPLE, tick_id, 
            StringFormat("🎯 %s (確信度: %.1f%%)", reason, strength * 100.0));
      }
      else
      {
         // 待機中は通常ログ（頻度を抑えたい場合はコメントアウト可）
         // data.AddLog(FUNC_ID_LOGIC_RSI_SIMPLE, tick_id, reason);
      }
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 閾値を動的に変更（オプション機能）                                   |
   //-------------------------------------------------------------------
   void SetThresholds(double oversold, double overbought)
   {
      m_oversold = oversold;
      m_overbought = overbought;
      PrintFormat("[RSI判断] 閾値変更: 売られすぎ=%.1f, 買われすぎ=%.1f",
         m_oversold, m_overbought);
   }
};

//+------------------------------------------------------------------+
//| End of CDecisionRSI_Simple.mqh                                   |
//+------------------------------------------------------------------+