//+------------------------------------------------------------------+
//| File    : CObservationPositionState.mqh                          |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Observation                                            |
//|                                                                  |
//| Phase C-7.1c 追加                                                |
//| ポジション状態専用の観測層                                         |
//|                                                                  |
//| Role                                                             |
//|  - ポジション保有状態を観測する                                    |
//|  - 含み益を計算する                                               |
//|  - BE条件達成を判定する                                           |
//|  - BE適用済みかを判定する                                          |
//|                                                                  |
//| Design Policy                                                    |
//|  - Interval制御とは独立して動作                                    |
//|  - 判断は一切行わない（観測のみ）                                  |
//|  - CLA_Data経由で結果を共有                                       |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CObservationBase.mqh"

//+------------------------------------------------------------------+
//| Class   : CObservationPositionState                              |
//| Purpose : ポジション状態観測（BE判定用）                           |
//+------------------------------------------------------------------+
class CObservationPositionState : public CObservationBase
{
private:
   double m_be_trigger_points;    // BEトリガー（points）
   double m_be_tolerance_points;  // BE適用済み判定の許容値（points）

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CObservationPositionState()
      : CObservationBase(FUNC_ID_PRICE_OBSERVER)  // 仮のID使用
   {
      m_be_trigger_points = 100.0;    // 10pips
      m_be_tolerance_points = 5.0;    // 0.5pips
   }

   //-------------------------------------------------------------------
   //| 初期化                                                            |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CObservationBase::Init())
      {
         Print("[PosStateObs] ベースクラス初期化失敗");
         return false;
      }

      Print("[PosStateObs] 初期化成功 BE_TRIGGER=", m_be_trigger_points, "points");
      return true;
   }

   //-------------------------------------------------------------------
   //| 終了処理                                                          |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[PosStateObs] 終了処理");
      CObservationBase::Deinit();
   }

   //-------------------------------------------------------------------
   //| 更新（ポジション状態観測）                                         |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // ========== ポジション存在確認 ==========
      int positions_total = PositionsTotal();
      bool has_position = (positions_total > 0);

      double profit_points = 0.0;
      bool be_reached = false;
      bool be_already_applied = false;

      if(has_position)
      {
         // ポジション情報取得
         ulong ticket = PositionGetTicket(0);
         if(ticket > 0)
         {
            double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            double current_sl = PositionGetDouble(POSITION_SL);
            ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

            // 現在価格取得
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double current_price = (pos_type == POSITION_TYPE_BUY) ? bid : ask;
            double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

            // 含み益計算（points）
            if(pos_type == POSITION_TYPE_BUY)
            {
               profit_points = (current_price - open_price) / point;
            }
            else
            {
               profit_points = (open_price - current_price) / point;
            }

            // BE条件達成判定
            be_reached = (profit_points >= m_be_trigger_points);

            // BE適用済み判定（SLが建値±許容値以内）
            double sl_distance_from_open = MathAbs(current_sl - open_price) / point;
            be_already_applied = (sl_distance_from_open < m_be_tolerance_points);
         }
      }

      // ========== CLA_Dataに格納 ==========
      data.SetHasPosition(has_position);
      data.SetProfitPoints(profit_points);
      data.SetBEReached(be_reached);
      data.SetBEAlreadyApplied(be_already_applied);

      // ログ出力
      Print("[Aegis-TRACE][PosObs] has_position=", has_position,
            " profit_points=", (int)profit_points,
            " be_reached=", be_reached,
            " be_applied=", be_already_applied);

      return true;
   }
};

//+------------------------------------------------------------------+
//| End of CObservationPositionState.mqh                             |
//+------------------------------------------------------------------+
