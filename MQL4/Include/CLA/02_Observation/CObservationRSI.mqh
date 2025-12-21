//+------------------------------------------------------------------+
//|                                           CObservationRSI.mqh    |
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
//| RSI観測クラス                                                      |
//+------------------------------------------------------------------+
class CObservationRSI : public CObservationBase
{
private:
   //--- メンバ変数
   int    m_handle;      // RSIインジケーターのハンドル
   int    m_period;      // RSI計算期間
   double m_last_value;  // 前回のRSI値
   
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //| [引数]                                                            |
   //|   period : RSI計算期間（デフォルト14）                              |
   //-------------------------------------------------------------------
   CObservationRSI(int period = 14) : CObservationBase(FUNC_ID_TECHNICAL_RSI)
   {
      m_handle = INVALID_HANDLE;
      m_period = period;
      m_last_value = 0.0;
   }
   
   //-------------------------------------------------------------------
   //| デストラクタ                                                       |
   //-------------------------------------------------------------------
   ~CObservationRSI()
   {
      if(m_handle != INVALID_HANDLE)
      {
         exMQL.IndicatorRelease(m_handle);
         m_handle = INVALID_HANDLE;
      }
   }

   //===================================================================
   // ▼▼▼ 定数の代わりにメソッドを使用 ▼▼▼
   //===================================================================
   double GetOverboughtLevel() const { return 70.0; } // 買われすぎ基準
   double GetOversoldLevel()   const { return 30.0; } // 売られすぎ基準
   //===================================================================
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CObservationBase::Init()) return false;
      
      // EXMQLを使ってRSIハンドルを作成
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
   //| 更新メソッド                                                       |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      if(m_handle == INVALID_HANDLE) return false;
      
      double rsi_buffer[];
      ArraySetAsSeries(rsi_buffer, true);
      
      // EXMQLを使ってバッファをコピー
      if(exMQL.CopyBuffer(m_handle, 0, 0, 1, rsi_buffer) <= 0) return false;
      
      m_last_value = rsi_buffer[0];
      
      //--- 判定ロジック（修正：メソッド呼び出しに変更）
      string status = "";
      if(m_last_value >= GetOverboughtLevel()) // ここを修正
      {
         status = "[買われすぎゾーン]";
      }
      else if(m_last_value <= GetOversoldLevel()) // ここを修正
      {
         status = "[売られすぎゾーン]";
      }
      else
      {
         status = "[中立]";
      }
      
      string log_message = StringFormat("RSI(%d): %.1f %s", m_period, m_last_value, status);
      data.AddLog(FUNC_ID_TECHNICAL_RSI, tick_id, log_message);
      
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
   //| 判定メソッド（修正：メソッド呼び出しに変更）                          |
   //-------------------------------------------------------------------
   bool IsOverbought() const { return (m_last_value >= GetOverboughtLevel()); }
   bool IsOversold()   const { return (m_last_value <= GetOversoldLevel()); }
};
//+------------------------------------------------------------------+