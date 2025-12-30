//+------------------------------------------------------------------+
//|                                          CExecutionBase.mqh      |
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
#include <EXMQL\EXMQL.mqh>

//+------------------------------------------------------------------+
//| 執行基底クラス                                                      |
//|                                                                  |
//| [概要]                                                            |
//|   判断層からの指令を受けて、実際の注文を執行する「Aegisの手」。        |
//|   EXMQL.mqhのグローバルインスタンス(exMQL)を活用し、                  |
//|   MT4/MT5の差異を意識せずに注文・決済できる。                        |
//|                                                                  |
//| [設計思想]                                                         |
//|   - 執行は「指令に忠実」                                             |
//|   - 判断はしない（Decision層の仕事）                                 |
//|   - エラーは必ず記録し、上位層に報告                                  |
//|   - EXMQLによるプラットフォーム差異の完全隠蔽                          |
//|   - 堅牢なエラーハンドリング（エラーコード必須確認）                    |
//|                                                                  |
//| [使用例]                                                          |
//|   CExecutionBase execution(123456);  // マジックナンバー指定        |
//|   execution.Init();                                              |
//|   execution.EntryBuy(0.1, 157.00, 157.50);  // 0.1ロット買い      |
//+------------------------------------------------------------------+
class CExecutionBase
{
protected:
   //--- メンバ変数
   int              m_magic_number;   // マジックナンバー
   bool             m_initialized;    // 初期化済みフラグ
   string           m_symbol;         // 取引通貨ペア
   int              m_slippage;       // スリッページ（pips）
   
public:
   //-------------------------------------------------------------------
   //| コンストラクタ                                                     |
   //| [引数]                                                            |
   //|   magic_number : マジックナンバー（自分の注文を識別）               |
   //|   slippage     : 許容スリッページ（pips、デフォルト3）              |
   //-------------------------------------------------------------------
   CExecutionBase(int magic_number, int slippage = 3)
   {
      m_magic_number = magic_number;
      m_initialized = false;
      m_symbol = _Symbol;
      m_slippage = slippage;
   }
   
   //-------------------------------------------------------------------
   //| デストラクタ                                                       |
   //-------------------------------------------------------------------
   virtual ~CExecutionBase()
   {
      // 特に何もしない
   }
   
   //-------------------------------------------------------------------
   //| 初期化メソッド                                                     |
   //-------------------------------------------------------------------
   virtual bool Init()
   {
      PrintFormat("[執行層] 初期化開始 (通貨ペア: %s, チャート通貨ペア: %s)", 
         m_symbol, _Symbol);
      
      // 通貨ペアの選択（存在確認）
      ResetLastError();
      if(!SymbolSelect(m_symbol, true))
      {
         int error = GetLastError();
         
         // フェイルセーフ: チャート通貨ペアそのものであり、価格が取得できればOKとする
         double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         
         PrintFormat("[執行層] デバッグ: SymbolSelect失敗 (Error: %d), Bid=%.5f, Ask=%.5f", 
            error, bid, ask);
         
         if(m_symbol == _Symbol && bid > 0 && ask > 0)
         {
            PrintFormat("[執行層] 警告: SymbolSelectはfalseを返しましたが、チャート通貨ペアのため続行します。(Error: %d)", 
               error);
         }
         else
         {
            PrintFormat("[執行層] エラー: 通貨ペア %s の選択に失敗しました。Error Code: %d", 
               m_symbol, error);
            return false;
         }
      }
      else
      {
         Print("[執行層] SymbolSelect成功");
      }
      
      // 最終確認: 価格が取得できるか
      double final_bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double final_ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      
      if(final_bid <= 0 || final_ask <= 0)
      {
         PrintFormat("[執行層] エラー: 通貨ペア %s の価格取得失敗 (Bid=%.5f, Ask=%.5f)", 
            m_symbol, final_bid, final_ask);
         return false;
      }
      
      m_initialized = true;
      PrintFormat("[執行層] 初期化成功 (マジックナンバー: %d, 通貨ペア: %s, Bid=%.5f, Ask=%.5f)",
         m_magic_number, m_symbol, final_bid, final_ask);
      return true;
   }
   
   //-------------------------------------------------------------------
   //| 終了処理メソッド                                                   |
   //-------------------------------------------------------------------
   virtual void Deinit()
   {
      Print("[執行層] 終了処理");
   }
   
   //-------------------------------------------------------------------
   //| 買いエントリー                                                     |
   //| [引数]                                                            |
   //|   volume   : ロット数                                             |
   //|   sl_price : ストップロス価格（0の場合は設定なし）                   |
   //|   tp_price : テイクプロフィット価格（0の場合は設定なし）             |
   //| [戻り値]                                                          |
   //|   true  : 注文成功                                                |
   //|   false : 注文失敗                                                |
   //-------------------------------------------------------------------
   bool EntryBuy(double volume, double sl_price = 0.0, double tp_price = 0.0)
   {
      if(!m_initialized)
      {
         Print("[執行層] エラー: 初期化されていません");
         return false;
      }
      
      // 現在の価格を取得
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      
      // トレードリクエスト構築
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      
      request.action = TRADE_ACTION_DEAL;
      request.symbol = m_symbol;
      request.volume = volume;
      request.type = ORDER_TYPE_BUY;
      request.price = ask;
      request.sl = sl_price;
      request.tp = tp_price;
      request.deviation = m_slippage;
      request.magic = m_magic_number;
      request.comment = "Aegis Buy";
      
      // グローバルEXMQLを使って注文送信
      ResetLastError();
      if(!exMQL.OrderSend(request, result))
      {
         int error = GetLastError();
         PrintFormat("[執行層] 買い注文失敗: エラーコード=%d, リターンコード=%d, 説明=%s",
            error, result.retcode, GetTradeResultDescription(result.retcode));
         return false;
      }
      
      if(result.retcode == TRADE_RETCODE_DONE || 
         result.retcode == TRADE_RETCODE_PLACED)
      {
         PrintFormat("[執行層] ✅ 買い注文成功: チケット=%I64u, ロット=%.2f, 価格=%.5f",
            result.order, volume, result.price);
         return true;
      }
      else
      {
         PrintFormat("[執行層] 買い注文失敗: リターンコード=%d, 説明=%s",
            result.retcode, GetTradeResultDescription(result.retcode));
         return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 売りエントリー                                                     |
   //| [引数]                                                            |
   //|   volume   : ロット数                                             |
   //|   sl_price : ストップロス価格（0の場合は設定なし）                   |
   //|   tp_price : テイクプロフィット価格（0の場合は設定なし）             |
   //| [戻り値]                                                          |
   //|   true  : 注文成功                                                |
   //|   false : 注文失敗                                                |
   //-------------------------------------------------------------------
   bool EntrySell(double volume, double sl_price = 0.0, double tp_price = 0.0)
   {
      if(!m_initialized)
      {
         Print("[執行層] エラー: 初期化されていません");
         return false;
      }
      
      // 現在の価格を取得
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      
      // トレードリクエスト構築
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);
      
      request.action = TRADE_ACTION_DEAL;
      request.symbol = m_symbol;
      request.volume = volume;
      request.type = ORDER_TYPE_SELL;
      request.price = bid;
      request.sl = sl_price;
      request.tp = tp_price;
      request.deviation = m_slippage;
      request.magic = m_magic_number;
      request.comment = "Aegis Sell";
      
      // グローバルEXMQLを使って注文送信
      ResetLastError();
      if(!exMQL.OrderSend(request, result))
      {
         int error = GetLastError();
         PrintFormat("[執行層] 売り注文失敗: エラーコード=%d, リターンコード=%d, 説明=%s",
            error, result.retcode, GetTradeResultDescription(result.retcode));
         return false;
      }
      
      if(result.retcode == TRADE_RETCODE_DONE || 
         result.retcode == TRADE_RETCODE_PLACED)
      {
         PrintFormat("[執行層] ✅ 売り注文成功: チケット=%I64u, ロット=%.2f, 価格=%.5f",
            result.order, volume, result.price);
         return true;
      }
      else
      {
         PrintFormat("[執行層] 売り注文失敗: リターンコード=%d, 説明=%s",
            result.retcode, GetTradeResultDescription(result.retcode));
         return false;
      }
   }
   
   //-------------------------------------------------------------------
   //| 全ポジション決済                                                   |
   //| [戻り値]                                                          |
   //|   true  : 全決済成功（またはポジションなし）                        |
   //|   false : 決済失敗                                                |
   //-------------------------------------------------------------------
   bool CloseAll()
   {
      if(!m_initialized)
      {
         Print("[執行層] エラー: 初期化されていません");
         return false;
      }
      
      int closed_count = 0;
      int total_positions = GetPositionCount();
      
      if(total_positions == 0)
      {
         Print("[執行層] 決済対象のポジションがありません");
         return true;
      }
      
      // EXMQLの統一APIで全ポジションをループ
      for(int i = exMQL.PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = exMQL.PositionGetTicket(i);
         if(ticket == 0) continue;
         
         // マジックナンバーと通貨ペアをチェック
         if(exMQL.PositionGetInteger(POSITION_MAGIC) != m_magic_number) continue;
         if(exMQL.PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
         
         // 決済リクエスト構築
         MqlTradeRequest request;
         MqlTradeResult result;
         ZeroMemory(request);
         ZeroMemory(result);
         
         request.action = TRADE_ACTION_DEAL;
         request.position = ticket;
         request.symbol = m_symbol;
         request.volume = exMQL.PositionGetDouble(POSITION_VOLUME);
         request.deviation = m_slippage;
         request.magic = m_magic_number;
         request.comment = "Aegis Close";
         
         // 買いポジションなら売り、売りポジションなら買いで決済
         if(exMQL.PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            request.type = ORDER_TYPE_SELL;
            request.price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
         }
         else
         {
            request.type = ORDER_TYPE_BUY;
            request.price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
         }
         
         // グローバルEXMQLを使って決済
         ResetLastError();
         if(exMQL.OrderSend(request, result))
         {
            if(result.retcode == TRADE_RETCODE_DONE || 
               result.retcode == TRADE_RETCODE_PLACED)
            {
               PrintFormat("[執行層] ✅ ポジション決済成功: チケット=%I64u", ticket);
               closed_count++;
            }
            else
            {
               PrintFormat("[執行層] ポジション決済失敗: チケット=%I64u, リターンコード=%d, エラー=%s",
                  ticket, result.retcode, GetTradeResultDescription(result.retcode));
            }
         }
         else
         {
            int error = GetLastError();
            PrintFormat("[執行層] ポジション決済失敗: チケット=%I64u, エラーコード=%d", 
               ticket, error);
         }
      }
      
      PrintFormat("[執行層] 全決済完了: %d/%d ポジション", closed_count, total_positions);
      return (closed_count > 0);
   }
   
   //-------------------------------------------------------------------
   //| 現在のポジション数を取得                                            |
   //-------------------------------------------------------------------
   int GetPositionCount()
   {
      int count = 0;
      int total = exMQL.PositionsTotal();
      
      for(int i = 0; i < total; i++)
      {
         if(exMQL.PositionGetTicket(i) == 0) continue;
         if(exMQL.PositionGetInteger(POSITION_MAGIC) != m_magic_number) continue;
         if(exMQL.PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
         count++;
      }
      
      return count;
   }
   
private:
   //-------------------------------------------------------------------
   //| トレード結果コード→日本語説明                                       |
   //-------------------------------------------------------------------
   string GetTradeResultDescription(uint retcode)
   {
      switch(retcode)
      {
         case TRADE_RETCODE_DONE:           return "成功";
         case TRADE_RETCODE_REJECT:         return "リクエスト拒否";
         case TRADE_RETCODE_CANCEL:         return "キャンセル";
         case TRADE_RETCODE_PLACED:         return "注文受付";
         case TRADE_RETCODE_INVALID:        return "無効なリクエスト";
         case TRADE_RETCODE_INVALID_VOLUME: return "無効なロット数";
         case TRADE_RETCODE_INVALID_PRICE:  return "無効な価格";
         case TRADE_RETCODE_INVALID_STOPS:  return "無効なストップ";
         case TRADE_RETCODE_TRADE_DISABLED: return "取引無効";
         case TRADE_RETCODE_MARKET_CLOSED:  return "市場休場";
         case TRADE_RETCODE_NO_MONEY:       return "資金不足";
         case TRADE_RETCODE_PRICE_CHANGED:  return "価格変更";
         case TRADE_RETCODE_CONNECTION:     return "接続エラー";
         default:                           return "不明なエラー";
      }
   }
};

//+------------------------------------------------------------------+
//| End of CExecutionBase.mqh                                        |
//+------------------------------------------------------------------+