//+------------------------------------------------------------------+
//| File    : CObservationPrice.mqh                                  |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Observation                                            |
//|                                                                  |
//| Role                                                             |
//|  - 現在の市場価格（Ask/Bid）を観測する                           |
//|  - スプレッドを計算する                                          |
//|  - NTick観測：期間内の高値・安値を記録する                       |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CObservationBase.mqh"
#include "../../EXMQL/EXMQL.mqh"

//+------------------------------------------------------------------+
//| Class   : CObservationPrice                                      |
//| Layer   : Observation                                            |
//+------------------------------------------------------------------+
class CObservationPrice : public CObservationBase
{
private:
   // 既存の状態
   double m_last_ask;
   double m_last_bid;
   double m_last_spread;
   
   // NTick観測用の状態
   int m_interval_size;          // インターバルサイズ
   int m_interval_counter;       // 現在のカウント
   ulong m_interval_id;          // インターバル通し番号
   
   double m_window_high;         // インターバル内最高値
   double m_window_low;          // インターバル内最安値
   bool m_interval_completed;    // インターバル完了フラグ

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CObservationPrice() : CObservationBase(FUNC_ID_PRICE_OBSERVER)
   {
      m_last_ask = 0.0;
      m_last_bid = 0.0;
      m_last_spread = 0.0;
      
      // NTick観測の初期化
      m_interval_size = 50;      // デフォルト値
      m_interval_counter = 0;
      m_interval_id = 0;
      m_window_high = 0.0;
      m_window_low = DBL_MAX;
      m_interval_completed = false;
   }

   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CObservationBase::Init()) return false;

      Print("[価格観測] 初期化成功");
      Print("[価格観測] NTick観測: インターバルサイズ=", m_interval_size);
      return true;
   }

   //-------------------------------------------------------------------
   //| 終了処理                                                           |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[価格観測] 終了処理");
      CObservationBase::Deinit();
   }
   
   //-------------------------------------------------------------------
   //| インターバルサイズの設定                                           |
   //-------------------------------------------------------------------
   void SetIntervalSize(int size)
   {
      if(size > 0)
      {
         m_interval_size = size;
      }
   }

   //-------------------------------------------------------------------
   //| 更新メソッド（NTick観測機能追加）                                  |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // 1. 現在価格取得
      m_last_ask = exMQL.SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      m_last_bid = exMQL.SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // スプレッド計算（pips）
      double point = exMQL.SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      int digits = (int)exMQL.SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

      double spread_points = (m_last_ask - m_last_bid) / point;
      m_last_spread = spread_points / 10.0; // pipsに変換
      
      // 2. NTick観測：ウィンドウ更新
      if(m_window_high < m_last_ask)
      {
         m_window_high = m_last_ask;
      }
      
      if(m_window_low > m_last_bid)
      {
         m_window_low = m_last_bid;
      }
      
      // 3. カウンタインクリメント
      m_interval_counter++;
      
      // 4. インターバル完了判定
      if(m_interval_counter >= m_interval_size)
      {
         // インターバル完了
         m_interval_completed = true;
         m_interval_id++;
         
         // ★重要：CLA_Dataへの書き込みはインターバル完了時のみ
         data.SetObs_IntervalCompleted(true);
         data.SetObs_WindowHigh(m_window_high);
         data.SetObs_WindowLow(m_window_low);
         data.SetObs_IntervalID(m_interval_id);
         
         // トレースログ
         Print("[Aegis-TRACE][Observation] interval_id=", m_interval_id, " completed");
         Print("[Aegis-TRACE][Observation] window_high=", DoubleToString(m_window_high, digits), 
               " window_low=", DoubleToString(m_window_low, digits));
         
         // 次のインターバル開始
         m_interval_counter = 0;
         m_window_high = 0.0;
         m_window_low = DBL_MAX;
      }
      else
      {
         // インターバル継続中
         m_interval_completed = false;
         data.SetObs_IntervalCompleted(false);
      }

      // 5. 既存処理：毎Tickの価格情報を記録
      data.SetMarketData(
         m_last_bid,
         m_last_ask,
         m_last_spread,
         TimeCurrent()
      );
      
      return true;
   }

   //-------------------------------------------------------------------
   //| 最後のAsk価格を取得                                               |
   //-------------------------------------------------------------------
   double GetLastAsk() const
   {
      return m_last_ask;
   }

   //-------------------------------------------------------------------
   //| 最後のBid価格を取得                                               |
   //-------------------------------------------------------------------
   double GetLastBid() const
   {
      return m_last_bid;
   }

   //-------------------------------------------------------------------
   //| 最後のスプレッドを取得                                             |
   //-------------------------------------------------------------------
   double GetLastSpread() const
   {
      return m_last_spread;
   }
};
//+------------------------------------------------------------------+
