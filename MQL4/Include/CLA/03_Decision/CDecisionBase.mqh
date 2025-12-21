//+------------------------------------------------------------------+
//|                                            CDecisionBase.mqh     |
//|                                  Copyright 2025, Aegis Project   |
//|                          https://github.com/YasuharuEA/Aegis     |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2025, Aegis Project"
#property link        "https://github.com/YasuharuEA/Aegis"
#property strict

//+------------------------------------------------------------------+
//| インクルード                                                        |
//+------------------------------------------------------------------+
#include "../00_Common/CLA_Common.mqh"
#include "../00_Common/CLA_Data.mqh"

//+------------------------------------------------------------------+
//| 判断基底クラス                                                      |
//|                                                                  |
//| [概要]                                                            |
//|   全ての判断ロジック（ロジックA、ロジックB等）の親クラス。           |
//|   観測層が集めた情報を読み取り、エントリー・決済の判断を下す。        |
//|                                                                  |
//| [設計思想]                                                         |
//|   - 判断は「事実に基づく意思決定」                                    |
//|   - 実行はしない（Execution層の仕事）                                |
//|   - 複数の判断ロジックが共存可能                                      |
//|   - 優先度により判断を上書き可能                                      |
//|                                                                  |
//| [継承例]                                                          |
//|   class CDecisionRSISimple : public CDecisionBase { ... }        |
//|   class CDecisionMACD      : public CDecisionBase { ... }        |
//+------------------------------------------------------------------+
class CDecisionBase
{
protected:
   //--- メンバ変数
   ENUM_FUNCTION_ID m_my_id;        // 自分の機能ID（ログ出力時に使用）
   bool             m_initialized;  // 初期化済みフラグ
   int              m_priority;     // 優先度（大きいほど優先）
   SignalData       m_last_signal;  // 最後に出した判断結果
   
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //| [引数]                                                            |
   //|   func_id  : この判断ロジックの機能ID                               |
   //|   priority : 優先度（デフォルト100）                                |
   //-------------------------------------------------------------------
   CDecisionBase(ENUM_FUNCTION_ID func_id, int priority = 100)
   {
      m_my_id = func_id;
      m_initialized = false;
      m_priority = priority;
      
      // シグナル初期化
      m_last_signal.source_id = func_id;
      m_last_signal.signal_type = SIGNAL_NONE;
      m_last_signal.strength = 0.0;
      m_last_signal.price = 0.0;
      m_last_signal.fire_time = 0;
   }
   
   //-------------------------------------------------------------------
   //| デストラクタ                                                       |
   //-------------------------------------------------------------------
   virtual ~CDecisionBase()
   {
      // 特に何もしない（必要なら子クラスで実装）
   }
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //| [戻り値]                                                          |
   //|   true  : 初期化成功                                              |
   //|   false : 初期化失敗                                              |
   //-------------------------------------------------------------------
   virtual bool Init()
   {
      // 基底クラスでは何もしない
      // 子クラスで必要な初期化処理を実装
      m_initialized = true;
      Print("[判断ベース] 初期化完了: ", EnumToString(m_my_id));
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit()
   {
      // 基底クラスでは何もしない
      // 子クラスで必要な終了処理を実装
      Print("[判断ベース] 終了処理: ", EnumToString(m_my_id));
   }
   
   //-------------------------------------------------------------------
   //| 更新メソッド（純粋仮想関数：子クラスで必ず実装すること）                |
   //| [引数]                                                            |
   //|   data    : システム共通データ（参照渡し）                            |
   //|   tick_id : この操作のユニークID                                    |
   //| [戻り値]                                                          |
   //|   true  : 更新成功                                                |
   //|   false : 更新失敗（エラー発生）                                    |
   //| [実装例]                                                          |
   //|   bool CDecisionRSISimple::Update(CLA_Data &data, ulong tick_id) |
   //|   {                                                              |
   //|      // RSI値を読み取る                                           |
   //|      // 買い/売り/待機を判断                                       |
   //|      // m_last_signalに結果を格納                                 |
   //|      // data.AddLog() でログ記録                                  |
   //|      return true;                                                |
   //|   }                                                              |
   //-------------------------------------------------------------------
   virtual bool Update(CLA_Data &data, ulong tick_id) = 0; // 純粋仮想関数
   
   //-------------------------------------------------------------------
   //| 最後の判断結果を取得                                                |
   //| [戻り値]                                                          |
   //|   SignalData : 最後に出した判断結果                                |
   //-------------------------------------------------------------------
   SignalData GetLastSignal() const
   {
      return m_last_signal;
   }
   
   //-------------------------------------------------------------------
   //| 自分の機能IDを取得                                                 |
   //-------------------------------------------------------------------
   ENUM_FUNCTION_ID GetFunctionID() const
   {
      return m_my_id;
   }
   
   //-------------------------------------------------------------------
   //| 優先度を取得                                                       |
   //-------------------------------------------------------------------
   int GetPriority() const
   {
      return m_priority;
   }
   
   //-------------------------------------------------------------------
   //| 初期化状態を取得                                                   |
   //-------------------------------------------------------------------
   bool IsInitialized() const
   {
      return m_initialized;
   }
   
protected:
   //-------------------------------------------------------------------
   //| 判断結果を保存（子クラスから呼び出す）                               |
   //| [引数]                                                            |
   //|   signal_type : 判断結果（BUY/SELL/NONE/EXIT_ALL）               |
   //|   strength    : 確信度（0.0〜1.0）                                |
   //|   price       : 判断時の価格（記録用）                              |
   //-------------------------------------------------------------------
   void SetSignal(ENUM_SIGNAL_TYPE signal_type, double strength, double price)
   {
      m_last_signal.source_id = m_my_id;
      m_last_signal.signal_type = signal_type;
      m_last_signal.strength = strength;
      m_last_signal.price = price;
      m_last_signal.fire_time = TimeLocal();
   }
};

//+------------------------------------------------------------------+
//| End of CDecisionBase.mqh                                         |
//+------------------------------------------------------------------+