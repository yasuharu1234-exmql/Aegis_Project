//+------------------------------------------------------------------+
//| File    : CDecisionArbiter.mqh                                   |
//| Project : Aegis Hybrid EA                                       |
//| Layer   : Decision                                               |
//|                                                                  |
//| フェーズC実装                                                      |
//| Decision Arbiter: 複数判断の調停・収束機構                         |
//|                                                                  |
//| Role                                                             |
//|  - 複数の判断ロジックからAction候補を収集                          |
//|  - 必ず「1 Tick = 1 Action」に収束                                |
//|  - 構造で排他を保証（if/switchの乱立を回避）                       |
//|                                                                  |
//| Design Philosophy                                                |
//|  - 「出口は常に1つ」を構造で保証                                   |
//|  - 判断ロジックがいくら増えても破綻しない                          |
//|  - 収束ロジックは単純でよい（フェーズCでは）                        |
//|                                                                  |
//| Responsibility                                                   |
//|  - 各判断ロジックの GenerateActionCandidate() を呼び出す          |
//|  - 複数の候補から1つのActionに収束                                 |
//|  - 最終Actionを返す（唯一の出口）                                 |
//|                                                                  |
//| Prohibited                                                       |
//|  - 実行層の呼び出し                                               |
//|  - ログの詳細組み込み                                             |
//|  - 複雑な最適化ロジック                                           |
//|  - 「どうすれば勝てるか」の考慮                                   |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright   "Copyright 2025, Aegis Project"
#property strict

#ifndef DECISION_ARBITER_MQH
#define DECISION_ARBITER_MQH

#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"
#include "CDecisionBase.mqh"

//+------------------------------------------------------------------+
//| Class   : CDecisionArbiter                                       |
//| Layer   : Decision                                               |
//| Purpose : 複数判断の調停・収束（唯一の出口）                       |
//+------------------------------------------------------------------+
class CDecisionArbiter
{
private:
   CDecisionBase* m_decisions[10];  // 判断ロジック配列（最大10個）
   int            m_decision_count;  // 登録済み判断ロジック数
   
   //-------------------------------------------------------------------
   //| フェーズC: 単純な収束ロジック                                       |
   //| [Strategy]                                                        |
   //|   優先度が最も高い判断ロジックのActionを採用                        |
   //|   同一優先度の場合は先に登録されたものを優先                        |
   //|                                                                  |
   //| [Note]                                                            |
   //|   フェーズD以降で高度な収束ロジックに置き換え可能                   |
   //|   例: スプレッド考慮、リスク評価、複数候補の統合等                  |
   //-------------------------------------------------------------------
   Action SelectByPriority(Action &candidates[], int candidate_count)
   {
      // 候補がない場合は ACTION_NONE
      if(candidate_count == 0)
      {
         Action none_action;
         none_action.type = ACTION_NONE;
         return none_action;
      }
      
      // 最初の候補をベースラインとする
      int best_index = 0;
      int best_priority = m_decisions[0].GetPriority();
      
      // 優先度が最も高い候補を探索
      for(int i = 1; i < candidate_count; i++)
      {
         int priority = m_decisions[i].GetPriority();
         if(priority > best_priority)
         {
            best_index = i;
            best_priority = priority;
         }
      }
      
      return candidates[best_index];
   }

public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //-------------------------------------------------------------------
   CDecisionArbiter()
   {
      m_decision_count = 0;
      // ArrayInitialize不要（構造体配列）
   }
   
   //-------------------------------------------------------------------
   //| 判断ロジックを登録                                                 |
   //| [引数]                                                            |
   //|   decision : 判断ロジックのポインタ                                |
   //| [戻り値]                                                          |
   //|   true  : 登録成功                                                |
   //|   false : 登録失敗（配列が満杯）                                   |
   //-------------------------------------------------------------------
   bool RegisterDecision(CDecisionBase &decision)
   {
      if(m_decision_count >= 10)
      {
         Print("⚠️ [DecisionArbiter] 判断ロジック登録失敗: 配列が満杯");
         return false;
      }
      
      m_decisions[m_decision_count] = GetPointer(decision);
      m_decision_count++;
      
      Print("✅ [DecisionArbiter] 判断ロジック登録: ", m_decision_count, "個目");
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 最終Action決定（唯一の出口）                                       |
   //| [引数]                                                            |
   //|   data    : システム共通データ                                     |
   //|   tick_id : この操作のユニークID                                   |
   //| [戻り値]                                                          |
   //|   Action  : 必ず1つのAction（構造で保証）                         |
   //|                                                                  |
   //| [Process]                                                         |
   //|   1. 全判断ロジックから候補を収集                                  |
   //|   2. 収束ロジックで1つに絞る                                       |
   //|   3. 最終Actionを返す                                             |
   //|                                                                  |
   //| [Guarantee]                                                       |
   //|   - 戻り値は必ず1つのAction                                       |
   //|   - ACTION_NONEも正当な戻り値                                     |
   //|   - 複数のActionが同時に返ることは構造的に不可能                   |
   //-------------------------------------------------------------------
   Action Decide(CLA_Data &data, ulong tick_id)
   {
      // ★★★ トレースログ: 開始 ★★★
      Print("[Aegis-TRACE][Arbiter] === Decide START ===");
      Print("[Aegis-TRACE][Arbiter] Registered Decisions: ", m_decision_count);
      
      // ========== ステップ1: 候補収集 ==========
      Action candidates[10];
      int valid_candidate_count = 0;
      
      for(int i = 0; i < m_decision_count; i++)
      {
         if(m_decisions[i] == NULL)
            continue;
         
         // 各判断ロジックから候補を取得
         Action candidate = m_decisions[i].GenerateActionCandidate(data, tick_id);
         
         // ★★★ トレースログ: 候補取得 ★★★
         Print("[Aegis-TRACE][Arbiter] Decision[", i, "] returned: ", candidate.type);
         
         // 候補を配列に格納
         candidates[valid_candidate_count] = candidate;
         valid_candidate_count++;
      }
      
      // ========== ステップ2: 収束 ==========
      // フェーズC: 優先度ベースの単純な収束
      Action final_action = SelectByPriority(candidates, valid_candidate_count);
      
      // ★★★ トレースログ: 最終決定 ★★★
      Print("[Aegis-TRACE][Arbiter] Final Action: ", final_action.type);
      
      // ========== ステップ3: 最終Action返却 ==========
      // ★ここが唯一の出口
      // ★どんな経路を通っても、必ず1つのActionが返る
      return final_action;
   }
   
   //-------------------------------------------------------------------
   //| 登録済み判断ロジック数を取得                                        |
   //-------------------------------------------------------------------
   int GetDecisionCount() const
   {
      return m_decision_count;
   }
};

#endif // DECISION_ARBITER_MQH

//+------------------------------------------------------------------+
//| End of CDecisionArbiter.mqh                                      |
//+------------------------------------------------------------------+
