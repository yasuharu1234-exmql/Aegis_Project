//+------------------------------------------------------------------+
//| File    : CStrategy_OCOFollow.mqh                                |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Decision / Strategy                                    |
//|                                                                  |
//| Role                                                             |
//|  - OCO（BuyStop/SellStop）を配置・管理する戦略                   |
//|  - 片側約定を検出し、反対側注文をキャンセルする                  |
//|  - 約定後のSL/TP追従は行わない（別Strategyへ委譲）               |
//|                                                                  |
//| Responsibility                                                   |
//|  - 判断のみ（OrderSendは絶対に使わない）                         |
//|  - CLA_Dataに対してSetExecRequest()で要求を出すのみ              |
//|  - 約定検出はPositionsTotal/OrdersTotalで状態確認のみ             |
//|                                                                  |
//| Design Policy (Sprint B)                                         |
//|  - OCO配置 → 片側約定検出 → 反対側キャンセル → 役割終了         |
//|  - 追従(MODIFY)は仮条件（毎Tick、現在価格±distance）             |
//|  - MODIFY は毎Tick1回まで                                        |
//|  - 約定検出後は即CANCEL → その後はNOOP                           |
//|                                                                  |
//| Prohibited                                                       |
//|  - Execution層のロジック変更                                     |
//|  - ログ追加（CLA_Dataに任せる）                                  |
//|  - Gatekeeper判断                                                |
//|  - SL/TP追従                                                     |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "../03_Decision/CDecisionBase.mqh"

//+------------------------------------------------------------------+
//| OCO追従戦略クラス                                                 |
//+------------------------------------------------------------------+
class CStrategy_OCOFollow : public CDecisionBase
{
private:
   //--- 内部状態
   enum ENUM_OCO_STATE
   {
      OCO_STATE_IDLE = 0,      // 未配置
      OCO_STATE_ACTIVE,        // OCO配置済み・追従中
      OCO_STATE_COMPLETED      // 役割完了（片側約定→反対側キャンセル済み）
   };
   
   ENUM_OCO_STATE m_state;           // 現在の状態
   bool           m_modify_done;     // 今Tickで既にMODIFY済みか
   
   //--- パラメータ
   double         m_distance_points; // OCO配置距離（ポイント）
   double         m_lot;              // ロットサイズ
   double         m_sl_points;        // SL（ポイント）
   double         m_tp_points;        // TP（ポイント）
   int            m_magic;            // マジックナンバー

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CStrategy_OCOFollow(double distance_points = 100.0,
                       double lot = 0.01,
                       double sl_points = 0.0,
                       double tp_points = 0.0,
                       int magic = 123456)
      : CDecisionBase(FUNC_ID_DECISION_EVALUATOR, 100) // ★OCO戦略用にDECISION_EVALUATORを使用
   {
      m_state = OCO_STATE_IDLE;
      m_modify_done = false;
      
      m_distance_points = distance_points;
      m_lot = lot;
      m_sl_points = sl_points;
      m_tp_points = tp_points;
      m_magic = magic;
   }
   
   //-------------------------------------------------------------------
   //| 初期化                                                             |
   //-------------------------------------------------------------------
   virtual bool Init() override
   {
      m_initialized = true;
      Print("[OCO戦略] 初期化完了: 距離=", m_distance_points, "pt, ロット=", m_lot);
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理                                                           |
   //-------------------------------------------------------------------
   virtual void Deinit() override
   {
      Print("[OCO戦略] 終了処理");
   }
   
   //-------------------------------------------------------------------
   //| メイン更新処理（毎Tick呼び出し）                                   |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) override
   {
      // Tick開始時にMODIFYフラグをリセット
      m_modify_done = false;
      
      // ========== 状態に応じた処理分岐 ==========
      switch(m_state)
      {
         case OCO_STATE_IDLE:
            return HandleIdle(data, tick_id);
            
         case OCO_STATE_ACTIVE:
            return HandleActive(data, tick_id);
            
         case OCO_STATE_COMPLETED:
            return HandleCompleted(data, tick_id);
            
         default:
            Print("❌ [OCO戦略] 未知の状態: ", m_state);
            return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 戦略完了状態を取得（Sprint E追加）                                  |
   //-------------------------------------------------------------------
   virtual bool IsCompleted() const override
   {
      return (m_state == OCO_STATE_COMPLETED);
   }

private:
   //-------------------------------------------------------------------
   //| 状態: IDLE（OCO未配置）                                            |
   //-------------------------------------------------------------------
   bool HandleIdle(CLA_Data &data, ulong tick_id)
   {
      // ========== 配置条件チェック ==========
      // 1. ポジションが存在しないこと
      if(PositionsTotal() > 0)
      {
         return true; // 何もしない（他戦略のポジションがある）
      }
      
      // 2. OCO注文が存在しないこと
      if(CountOCOOrders(data) > 0)
      {
         return true; // 既に注文がある（異常状態だが安全のため何もしない）
      }
      
      // ========== OCO配置要求 ==========
      // パラメータをCLA_Dataに設定
      data.SetOCOLot(m_lot);
      data.SetOCODistancePoints(m_distance_points);
      data.SetOCOSLPoints(m_sl_points);
      data.SetOCOTPPoints(m_tp_points);
      data.SetOCOMagic(m_magic);
      
      // Execution層に配置要求
      data.SetExecRequest(EXEC_REQ_PLACE, tick_id);
      
      // 状態遷移
      m_state = OCO_STATE_ACTIVE;
      
      Print("✅ [OCO戦略] OCO配置要求: 距離=", m_distance_points, "pt");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 状態: ACTIVE（OCO配置済み・追従中）                                |
   //-------------------------------------------------------------------
   bool HandleActive(CLA_Data &data, ulong tick_id)
   {
      // ========== 約定検出 ==========
      if(PositionsTotal() > 0)
      {
         // 片側が約定した → 反対側をキャンセル
         Print("✅ [OCO戦略] 片側約定を検出 → 反対側キャンセル要求");
         data.SetExecRequest(EXEC_REQ_CANCEL, tick_id);
         
         // 状態遷移
         m_state = OCO_STATE_COMPLETED;
         return true;
      }
      
      // ========== 追従（MODIFY）判定 ==========
      // 同一Tick 1回まで
      if(m_modify_done)
         return true;
      
      // OCOチケット確認
      ulong buy_ticket  = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      if(buy_ticket == 0 && sell_ticket == 0)
         return true; // 注文が存在しない
      
      // 現在価格取得
      double ask   = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      double bid   = SymbolInfoDouble(Symbol(), SYMBOL_BID);
      double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
      
      if(ask <= 0 || bid <= 0 || point <= 0)
         return true; // 価格取得失敗
      
      // 新価格計算
      int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
      double new_buy  = NormalizeDouble(ask + m_distance_points * point, digits);
      double new_sell = NormalizeDouble(bid - m_distance_points * point, digits);
      
      bool need_modify = false;
      
      // BuyStop：価格を下げられるなら有利
      if(buy_ticket > 0 && new_buy < data.GetOCOBuyPrice())
      {
         data.SetOCOBuyPrice(new_buy);
         need_modify = true;
      }
      
      // SellStop：価格を上げられるなら有利
      if(sell_ticket > 0 && new_sell > data.GetOCOSellPrice())
      {
         data.SetOCOSellPrice(new_sell);
         need_modify = true;
      }
      
      if(need_modify)
      {
         data.SetExecRequest(EXEC_REQ_MODIFY, tick_id);
         m_modify_done = true;
         Print("✅ [OCO戦略] 追従更新要求: Buy=", new_buy, " Sell=", new_sell);
      }
      
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 状態: COMPLETED（役割完了）                                        |
   //-------------------------------------------------------------------
   bool HandleCompleted(CLA_Data &data, ulong tick_id)
   {
      // ========== NOOP ==========
      // 何もしない（別Strategyにバトンタッチ）
      return true;
   }
   
   //-------------------------------------------------------------------
   //| OCO注文数をカウント                                                |
   //-------------------------------------------------------------------
   int CountOCOOrders(CLA_Data &data)
   {
      int count = 0;
      ulong buy_ticket = data.GetOCOBuyTicket();
      ulong sell_ticket = data.GetOCOSellTicket();
      
      // BuyStopの存在確認
      if(buy_ticket > 0)
      {
         if(OrderSelect(buy_ticket))
         {
            count++;
         }
      }
      
      // SellStopの存在確認
      if(sell_ticket > 0)
      {
         if(OrderSelect(sell_ticket))
         {
            count++;
         }
      }
      
      return count;
   }
};
