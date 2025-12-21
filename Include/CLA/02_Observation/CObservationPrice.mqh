//+------------------------------------------------------------------+
//|                                      CObservationPrice.mqh       |
//|                                  Copyright 2025, Aegis Project   |
//|                          https://github.com/YasuharuEA/Aegis     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Aegis Project"
#property link        "https://github.com/YasuharuEA/Aegis"
#property strict

//+------------------------------------------------------------------+
//| インクルード                                                        |
//+------------------------------------------------------------------+
#include "CObservationBase.mqh"
#include <EXMQL\EXMQL.mqh>

//+------------------------------------------------------------------+
//| 価格観測クラス                                                      |
//+------------------------------------------------------------------+
class CObservationPrice : public CObservationBase
{
private:
   //--- メンバ変数
   double m_last_ask;    // 前回のAsk価格
   double m_last_bid;    // 前回のBid価格
   double m_last_spread; // 前回のスプレッド（pips）
   
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
   //| デストラクタ                                                       |
   //-------------------------------------------------------------------
   ~CObservationPrice()
   {
      // 特に何もしない
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
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[価格観測] 終了処理");
      CObservationBase::Deinit();
   }
   
   //-------------------------------------------------------------------
   //| 更新メソッド                                                       |
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
      
      // ログ記録
      string log_message = StringFormat(
         "Ask: %.5f, Bid: %.5f, スプレッド: %.1f pips",
         m_last_ask, m_last_bid, m_last_spread
      );
      data.AddLog(FUNC_ID_PRICE_OBSERVER, tick_id, log_message);
      
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
   //| 最後のスプレッドを取得（pips）                                      |
   //-------------------------------------------------------------------
   double GetLastSpread() const
   {
      return m_last_spread;
   }
};
//+------------------------------------------------------------------+