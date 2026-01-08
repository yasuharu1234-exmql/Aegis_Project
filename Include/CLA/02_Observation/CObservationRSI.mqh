//+------------------------------------------------------------------+
//| File    : CObservationRSI.mqh                                    |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Observation                                            |
//|                                                                  |
//| Role                                                             |
//|  - RSI（相対力指数）を観測する                                   |
//|  - 買われすぎ/売られすぎの判定を行う                              |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CObservationBase.mqh"
#include "../../EXMQL/EXMQL.mqh"

//+------------------------------------------------------------------+
//| Class   : CObservationRSI                                        |
//| Layer   : Observation                                            |
//+------------------------------------------------------------------+
class CObservationRSI : public CObservationBase
{
private:
   int m_handle;               // RSIインジケータハンドル
   int m_period;               // RSI期間
   double m_last_value;        // 最後のRSI値
   double m_overbought_level;  // 買われすぎレベル
   double m_oversold_level;    // 売られすぎレベル

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CObservationRSI() : CObservationBase(FUNC_ID_TECHNICAL_RSI)
   {
      m_handle = INVALID_HANDLE;
      m_period = 14;
      m_last_value = 50.0;
      m_overbought_level = 70.0;
      m_oversold_level = 30.0;
   }

   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CObservationBase::Init()) return false;

      // RSIインジケータハンドル作成
      m_handle = exMQL.iRSI(_Symbol, PERIOD_CURRENT, m_period, PRICE_CLOSE);

      if(m_handle == INVALID_HANDLE)
      {
         Print("[RSI観測] ハンドル作成失敗");
         return false;
      }

      Print("[RSI観測] 初期化成功 (期間:", m_period, ")");
      return true;
   }

   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      if(m_handle != INVALID_HANDLE)
      {
         exMQL.IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
      }
      CObservationBase::Deinit();
   }

   //-------------------------------------------------------------------
   //| 更新メソッド（Phase 5: ログ削除）                                  |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      if(m_handle == INVALID_HANDLE) return false;

      double rsi_buffer[];
      ArraySetAsSeries(rsi_buffer, true);

      // EXMQLを使ってバッファをコピー
      if(exMQL.CopyBuffer(m_handle, 0, 0, 1, rsi_buffer) <= 0) return false;

      m_last_value = rsi_buffer[0];


      // ★フェーズB追加: CLA_DataにRSI値を格納（観測層→判断層のデータ受け渡し）
      data.SetRSIValue(m_last_value);
      // ★Phase 5: 毎Tickログを削除
      // 判定ロジックは残すが、ログ出力は削除
      /*
      string status = "";
      if(m_last_value >= GetOverboughtLevel())
      {
         status = "[買われすぎゾーン]";
      }
      else if(m_last_value <= GetOversoldLevel())
      {
         status = "[売られすぎゾーン]";
      }
      else
      {
         status = "[中立]";
      }

      string log_message = StringFormat("RSI(%d): %.1f %s", m_period, m_last_value, status);
      data.AddLog(FUNC_ID_TECHNICAL_RSI, tick_id, log_message);
      */

      return true;
   }

   //-------------------------------------------------------------------
   //| 最後のRSI値を取得                                                 |
   //-------------------------------------------------------------------
   double GetLastValue() const
   {
      return m_last_value;
   }

   //-------------------------------------------------------------------
   //| 買われすぎレベルを取得                                             |
   //-------------------------------------------------------------------
   double GetOverboughtLevel() const
   {
      return m_overbought_level;
   }

   //-------------------------------------------------------------------
   //| 売られすぎレベルを取得                                             |
   //-------------------------------------------------------------------
   double GetOversoldLevel() const
   {
      return m_oversold_level;
   }
};
//+------------------------------------------------------------------+
