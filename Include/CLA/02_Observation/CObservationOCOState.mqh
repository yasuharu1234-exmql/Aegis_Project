//+------------------------------------------------------------------+
//| File    : CObservationOCOState.mqh                               |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Observation                                            |
//|                                                                  |
//| フェーズB実装                                                      |
//| 追従型OCO戦略用の観測層                                            |
//|                                                                  |
//| Role                                                             |
//|  - OCO注文（約定前注文）の有無を観測する                           |
//|  - ポジション（約定済み）の有無を観測する                           |
//|  - 「エントリー可能か否か」を事実として通知する                     |
//|                                                                  |
//| Design Policy                                                    |
//|  - 判断はしない（事実のみを通知）                                  |
//|  - CLA_Dataに結果を格納                                           |
//|  - 観測結果は二値のみ（エントリー可/不可）                          |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CObservationBase.mqh"
#include "../../EXMQL/EXMQL.mqh"

//+------------------------------------------------------------------+
//| Class   : CObservationOCOState                                   |
//| Layer   : Observation                                            |
//| Purpose : 追従型OCO用の状態観測                                    |
//+------------------------------------------------------------------+
class CObservationOCOState : public CObservationBase
{
private:
   int m_magic_number;    // 監視対象のマジックナンバー
   bool m_last_state;     // 最後の観測結果（エントリー可能フラグ）

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //| [引数]                                                            |
   //|   magic : 監視対象のマジックナンバー                                |
   //-------------------------------------------------------------------
   CObservationOCOState(int magic = 0) : CObservationBase(FUNC_ID_PRICE_OBSERVER)
   {
      m_magic_number = magic;
      m_last_state = false;
   }
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CObservationBase::Init()) return false;
      
      Print("[OCO状態観測] 初期化成功 (Magic: ", m_magic_number, ")");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[OCO状態観測] 終了処理");
      CObservationBase::Deinit();
   }
   
   //-------------------------------------------------------------------
   //| 更新メソッド（フェーズB実装）                                       |
   //| [引数]                                                            |
   //|   data    : システム共通データ（参照渡し）                            |
   //|   tick_id : この操作のユニークID                                    |
   //| [戻り値]                                                          |
   //|   true  : 更新成功                                                |
   //|   false : 更新失敗                                                |
   //|                                                                  |
   //| [観測する事実]                                                     |
   //|   - 約定前注文（BuyStop/SellStop）が存在するか                      |
   //|   - ポジション（約定済み）が存在するか                               |
   //|                                                                  |
   //| [判断基準]                                                         |
   //|   両方なし → エントリー可能（true）                                 |
   //|   どちらか存在 → エントリー不可（false）                             |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // 約定前注文の有無をチェック
      bool has_pending = HasPendingOrders();
      
      // ポジションの有無をチェック
      bool has_position = HasPositions();
      
      // エントリー可能判定（両方なければtrue）
      bool is_entry_clear = !has_pending && !has_position;
      
      // ★フェーズB: CLA_Dataに観測結果を格納
      data.SetObs_EntryClear(is_entry_clear);
      
      // 状態保存
      m_last_state = is_entry_clear;
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 最後の観測結果を取得                                                |
   //-------------------------------------------------------------------
   bool GetLastState() const
   {
      return m_last_state;
   }
   
private:
   //-------------------------------------------------------------------
   //| 約定前注文の有無をチェック                                          |
   //| [戻り値]                                                          |
   //|   true  : 約定前注文が存在する                                     |
   //|   false : 約定前注文なし                                           |
   //-------------------------------------------------------------------
   bool HasPendingOrders()
   {
      int total = exMQL.OrdersTotal();
      
      for(int i = 0; i < total; i++)
      {
         if(!exMQL.OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
         
         // マジックナンバーチェック
         if(exMQL.OrderMagicNumber() != m_magic_number)
            continue;
         
         // シンボルチェック
         if(exMQL.OrderSymbol() != _Symbol)
            continue;
         
         // 注文タイプチェック（BuyStop or SellStop）
         int order_type = exMQL.OrderType();
         if(order_type == OP_BUYSTOP || order_type == OP_SELLSTOP)
         {
            return true;  // 約定前注文あり
         }
      }
      
      return false;  // 約定前注文なし
   }
   
   //-------------------------------------------------------------------
   //| ポジションの有無をチェック                                          |
   //| [戻り値]                                                          |
   //|   true  : ポジションが存在する                                     |
   //|   false : ポジションなし                                           |
   //-------------------------------------------------------------------
   bool HasPositions()
   {
      int total = exMQL.OrdersTotal();
      
      for(int i = 0; i < total; i++)
      {
         if(!exMQL.OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            continue;
         
         // マジックナンバーチェック
         if(exMQL.OrderMagicNumber() != m_magic_number)
            continue;
         
         // シンボルチェック
         if(exMQL.OrderSymbol() != _Symbol)
            continue;
         
         // ポジションタイプチェック（Buy or Sell）
         int order_type = exMQL.OrderType();
         if(order_type == OP_BUY || order_type == OP_SELL)
         {
            return true;  // ポジションあり
         }
      }
      
      return false;  // ポジションなし
   }
};

//+------------------------------------------------------------------+
//| End of CObservationOCOState.mqh                                  |
//+------------------------------------------------------------------+
