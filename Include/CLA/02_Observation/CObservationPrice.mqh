//+------------------------------------------------------------------+
//| File    : CObservationPrice.mqh                                  |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Observation                                            |
//|                                                                  |
//| Role                                                             |
//|  - 現在の市場価格（Ask/Bid）を観測する                           |
//|  - スプレッドを計算する                                          |
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
   double m_last_ask;
   double m_last_bid;
   double m_last_spread;

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CObservationPrice() : CObservationBase(FUNC_ID_PRICE_OBSERVER)
   {
      m_last_ask = 0.0;
      m_last_bid = 0.0;
      m_last_spread = 0.0;
   }
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CObservationBase::Init()) return false;
      
      Print("[価格観測] 初期化成功");
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
   //| 更新メソッド（Phase 5: ログ削除）                                  |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // EXMQLを使って価格情報を取得
      m_last_ask = exMQL.SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      m_last_bid = exMQL.SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      // スプレッド計算（pips）
      double point = exMQL.SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      int digits = (int)exMQL.SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      
      double spread_points = (m_last_ask - m_last_bid) / point;
      m_last_spread = spread_points / 10.0; // pipsに変換
      
      // ★Phase 5: 毎Tickログを削除
      // data.AddLog(FUNC_ID_PRICE_OBSERVER, tick_id, log_message);
      
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
