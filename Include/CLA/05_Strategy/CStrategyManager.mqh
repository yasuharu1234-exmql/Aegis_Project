//+------------------------------------------------------------------+
//| File    : CStrategyManager.mqh                                   |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Strategy Management                                    |
//|                                                                  |
//| Role                                                             |
//|  - Strategy を「直呼び」から解放する                             |
//|  - 現在アクティブな Strategy を保持・呼び出し                    |
//|  - COMPLETED 状態を検知して切り替えを準備する                    |
//|                                                                  |
//| Responsibility                                                   |
//|  - Strategy を1つだけ保持（参照渡し）                            |
//|  - 毎Tick、その Strategy の Update() を呼ぶ                      |
//|  - IsCompleted() で完了検知（MQL準拠・安全）                     |
//|                                                                  |
//| Design Policy (Sprint E-2)                                       |
//|  - ポインタは最小限使用（参照保持のみ）                          |
//|  - dynamic_cast 不使用（RTTI なし環境対応）                      |
//|  - 仮想関数による完了検知（Option C）                            |
//|  - 判断しない（呼び出すだけ）                                    |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#ifndef STRATEGY_MANAGER_MQH
#define STRATEGY_MANAGER_MQH

#include "../00_Common/CLA_Data.mqh"
#include "../03_Decision/CDecisionBase.mqh"

//+------------------------------------------------------------------+
//| Strategy 管理クラス（MQL準拠版）                                  |
//+------------------------------------------------------------------+
class CStrategyManager
{
private:
   CDecisionBase* m_current;     // 現在アクティブな Strategy（参照保持のみ）
   bool           m_has_strategy; // Strategy が存在するか

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CStrategyManager()
   {
      m_current = NULL;
      m_has_strategy = false;
   }
   
   //-------------------------------------------------------------------
   //| 初期化                                                             |
   //| [引数]                                                            |
   //|   initial_strategy : 初期 Strategy のポインタ（参照のみ保持）     |
   //-------------------------------------------------------------------
   void Init(CDecisionBase &initial_strategy)
   {
      m_current = GetPointer(initial_strategy);
      m_has_strategy = true;
      Print("✅ [StrategyManager] 初期化完了: Strategy登録済み");
   }
   
   //-------------------------------------------------------------------
   //| 更新処理（毎Tick呼び出し）- MQL準拠版                              |
   //-------------------------------------------------------------------
   void Update(CLA_Data &data, ulong tick_id)
   {
      // ========== Strategy 存在チェック ==========
      if(!m_has_strategy || m_current == NULL)
      {
         // Strategy が存在しない → 何もしない（正常系）
         return;
      }
      
      // ========== 現在の Strategy を実行 ==========
      // ★MQL準拠: GetPointer経由で取得した参照を使用
      if(!m_current.Update(data, tick_id))
      {
         // Update が false を返した場合（エラー発生）
         Print("⚠️ [StrategyManager] Strategy Update が失敗しました");
         // エラー時も継続（Strategy 側で対処済みと判断）
      }
      
      // ========== COMPLETED 検知（MQL準拠・安全） ==========
      // ★仮想関数による完了検知（dynamic_cast 不要）
      if(m_current.IsCompleted())
      {
         Print("✅ [StrategyManager] Strategy COMPLETED → 呼び出し停止");
         m_has_strategy = false;
         // m_current はクリアしない（Phase F で再利用の可能性）
         // 次の Strategy は Phase F で実装予定
      }
   }
   
   //-------------------------------------------------------------------
   //| 現在の Strategy が存在するか                                       |
   //-------------------------------------------------------------------
   bool HasStrategy() const
   {
      return m_has_strategy;
   }
   
   //-------------------------------------------------------------------
   //| Strategy を切り替え（Phase F 用に予約）                           |
   //-------------------------------------------------------------------
   void SwitchStrategy(CDecisionBase &next_strategy)
   {
      Print("✅ [StrategyManager] Strategy 切り替え");
      m_current = GetPointer(next_strategy);
      m_has_strategy = true;
   }
};

#endif // STRATEGY_MANAGER_MQH
