//+------------------------------------------------------------------+
//| File    : CDecisionOCOFollow.mqh                                 |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Decision                                               |
//|                                                                  |
//| フェーズB実装                                                      |
//| 追従型OCO戦略用の判断層                                            |
//|                                                                  |
//| Role                                                             |
//|  - 観測層から「エントリー可能か否か」の事実を取得する                |
//|  - フェーズBでは受信確認のみ（Action決定はフェーズC以降）            |
//|                                                                  |
//| Design Policy                                                    |
//|  - CLA_Data経由でのみ観測結果を取得（観測層への直接参照なし）        |
//|  - フェーズBでは判断ロジックを実装しない                            |
//|  - Decision ArbiterはフェーズC以降                                |
//|                                                                  |
//| Future (フェーズC以降)                                             |
//|  - エントリー可否の最終判断                                         |
//|  - 追従型OCOのAction生成                                           |
//|  - Decision Arbiterとの連携                                       |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CDecisionBase.mqh"

//+------------------------------------------------------------------+
//| Class   : CDecisionOCOFollow                                     |
//| Layer   : Decision                                               |
//| Purpose : 追従型OCO戦略の判断層（フェーズB: 最小実装）              |
//+------------------------------------------------------------------+
class CDecisionOCOFollow : public CDecisionBase
{
private:
   bool m_last_entry_clear;  // 最後に取得したエントリー可能状態

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //| [引数]                                                            |
   //|   priority : 優先度（デフォルト100）                                |
   //-------------------------------------------------------------------
   CDecisionOCOFollow(int priority = 100) 
      : CDecisionBase(FUNC_ID_LOGIC_RSI_SIMPLE, priority)
   {
      m_last_entry_clear = false;
   }
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      if(!CDecisionBase::Init())
      {
         Print("[OCOFollow判断] 初期化失敗");
         return false;
      }
      
      m_last_entry_clear = false;
      
      Print("[OCOFollow判断] 初期化成功（フェーズB: 観測データ受信確認のみ）");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[OCOFollow判断] 終了処理");
      CDecisionBase::Deinit();
   }
   
   //-------------------------------------------------------------------
   //| 更新メソッド（フェーズB実装: 受信確認のみ）                         |
   //| [引数]                                                            |
   //|   data    : システム共通データ（参照渡し）                            |
   //|   tick_id : この操作のユニークID                                    |
   //| [戻り値]                                                          |
   //|   true  : 更新成功                                                |
   //|   false : 更新失敗                                                |
   //|                                                                  |
   //| [フェーズB実装内容]                                                |
   //|   - CLA_Dataから観測結果を取得                                     |
   //|   - 受信できることを確認するだけ                                    |
   //|   - Signal生成・Action決定は行わない                               |
   //|                                                                  |
   //| [フェーズC以降の実装予定]                                           |
   //|   - エントリー可否の最終判断                                        |
   //|   - 追従型OCOのAction生成                                          |
   //|   - Decision Arbiterとの連携                                      |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // ★フェーズB: CLA_Dataから観測結果を取得
      bool entry_clear = data.GetObs_EntryClear();
      
      // 状態保存（フェーズBでは使用しない）
      m_last_entry_clear = entry_clear;
      
      // ★フェーズB: 受信確認のみ（ログ出力なし、Signal生成なし）
      // この時点では何もしない
      
      // フェーズC以降で実装予定:
      // - if(entry_clear) { ... Action生成 ... }
      // - Decision Arbiterへの登録
      // - ログ出力
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 最後に取得したエントリー可能状態を取得                               |
   //| [戻り値]                                                          |
   //|   true  : エントリー可能                                           |
   //|   false : エントリー不可                                           |
   //| [Note]                                                            |
   //|   フェーズBでは参照用のみ                                          |
   //-------------------------------------------------------------------
   bool GetLastEntryClear() const
   {
      return m_last_entry_clear;
   }
};

//+------------------------------------------------------------------+
//| End of CDecisionOCOFollow.mqh                                    |
//+------------------------------------------------------------------+
