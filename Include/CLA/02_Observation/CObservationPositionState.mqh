//+------------------------------------------------------------------+
//| File    : CObservationPositionState.mqh                          |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Observation                                            |
//|                                                                  |
//| Phase C-7.1c 追加・Phase C-7.2 拡張                              |
//| ポジション状態専用の観測層                                         |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CObservationBase.mqh"

//+------------------------------------------------------------------+
//| Class   : CObservationPositionState                              |
//+------------------------------------------------------------------+
class CObservationPositionState : public CObservationBase
{
private:
   double m_be_trigger_points;
   double m_be_tolerance_points;
   
   // Phase C-7.2: 挟み撃ちトレイル用
   bool   m_tracking_initialized;
   double m_tracked_min_price;
   double m_tracked_max_price;
   double m_last_sl;
   double m_last_tp;

public:
   CObservationPositionState() : CObservationBase(FUNC_ID_PRICE_OBSERVER)
   {
      m_be_trigger_points = 100.0;
      m_be_tolerance_points = 5.0;
      m_tracking_initialized = false;
      m_tracked_min_price = 0.0;
      m_tracked_max_price = 0.0;
      m_last_sl = 0.0;
      m_last_tp = 0.0;
   }

   virtual bool Init() override
   {
      if(!CObservationBase::Init()) return false;
      Print("[PosStateObs] 初期化成功 BE_TRIGGER=", m_be_trigger_points, "points");
      return true;
   }

   virtual void Deinit() override
   {
      Print("[PosStateObs] 終了処理");
      CObservationBase::Deinit();
   }

   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      Print("[DEBUG][PosObs] Update called tick=", tick_id);  // Phase C-7.2a': デバッグ用
      
      int positions_total = PositionsTotal();
      bool has_position = (positions_total > 0);
      double profit_points = 0.0;
      bool be_reached = false;
      bool be_already_applied = false;
      double current_sl = 0.0;
      double current_tp = 0.0;
      double open_price = 0.0;
      ENUM_POSITION_TYPE pos_type = POSITION_TYPE_BUY;
      double current_price = 0.0;

      if(has_position)
      {
         ulong ticket = PositionGetTicket(0);
         if(ticket > 0)
         {
            open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            current_sl = PositionGetDouble(POSITION_SL);
            current_tp = PositionGetDouble(POSITION_TP);
            pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            current_price = (pos_type == POSITION_TYPE_BUY) ? bid : ask;
            double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

            if(pos_type == POSITION_TYPE_BUY)
               profit_points = (current_price - open_price) / point;
            else
               profit_points = (open_price - current_price) / point;

            be_reached = (profit_points >= m_be_trigger_points);
            double sl_distance_from_open = MathAbs(current_sl - open_price) / point;
            be_already_applied = (sl_distance_from_open < m_be_tolerance_points);
            
            // Phase C-7.2: 挟み撃ち追跡
            if(be_already_applied)
            {
               bool need_reset = false;
               if(!m_tracking_initialized)
                  need_reset = true;
               else if(MathAbs(current_sl - m_last_sl) > 0.0001 || 
                       MathAbs(current_tp - m_last_tp) > 0.0001)
                  need_reset = true;
               
               if(need_reset)
               {
                  m_tracked_min_price = current_price;
                  m_tracked_max_price = current_price;
                  m_tracking_initialized = true;
                  // Phase C-7.2a: Print削除
               }
               else
               {
                  if(current_price < m_tracked_min_price) m_tracked_min_price = current_price;
                  if(current_price > m_tracked_max_price) m_tracked_max_price = current_price;
               }
               m_last_sl = current_sl;
               m_last_tp = current_tp;
            }
            else
            {
               m_tracking_initialized = false;
               m_tracked_min_price = 0.0;
               m_tracked_max_price = 0.0;
            }
         }
      }
      else
      {
         m_tracking_initialized = false;
         m_tracked_min_price = 0.0;
         m_tracked_max_price = 0.0;
      }

      data.SetHasPosition(has_position);
      data.SetProfitPoints(profit_points);
      data.SetBEReached(be_reached);
      data.SetBEAlreadyApplied(be_already_applied);
      data.SetSandwichTracking(m_tracking_initialized, m_tracked_min_price, m_tracked_max_price,
                               current_sl, current_tp, open_price);

      // Phase C-7.2a': デバッグログ（一時的）
      Print("[DEBUG][PosObs] has_position=", has_position, 
            " profit_points=", (int)profit_points,
            " be_reached=", be_reached, 
            " be_applied=", be_already_applied);
      
      return true;
   }
};
