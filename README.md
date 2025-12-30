# Aegis_Project

Aegis_Project は、MetaTrader 4 / MetaTrader 5 向けに開発された  
**Aegis シリーズ EA の共通基盤となるプロジェクト** です。

本プロジェクトは、以下の3つのレイヤーで構成されています。

---

## ■ 1. EA（Experts）
`Aegis_Hybrid.mq4 / mq5`  
Aegis シリーズの実行ユニットとなる EA 本体です。  
ロジックの大部分は Include 配下のライブラリに委譲し、  
EA 本体は薄いラッパーとして動作します。

---

## ■ 2. CLA（Cognitive Layer Architecture）
`Include/CLA/`  
Aegis の「思考・判断」を担う中核レイヤーです。  
ロジックの分離、拡張性、AI との協調を目的として設計されています。

---

## ■ 3. EXMQL（MT4/MT5 差異吸収レイヤー）
`Include/EXMQL/`  
MT4 と MT5 の仕様差を吸収し、  
Aegis のロジックを共通化するための抽象化レイヤーです。

---

## ■ 対応プラットフォーム
- MetaTrader 4（MQL4）
- MetaTrader 5（MQL5）

---

## ■ ディレクトリ構造（概要）

## ■ ディレクトリ構造（概要）

```
Aegis_Project/
 ├── MQL4/
 │     ├── Experts/
 │     │     └── Aegis/
 │     │           └── Aegis_Hybrid.mq4
 │     └── Include/
 │           ├── CLA/
 │           └── EXMQL/
 │
 └── MQL5/
       ├── Experts/
       │     └── Aegis/
       │           └── Aegis_Hybrid.mq5
       └── Include/
             ├── CLA/
             └── EXMQL/
```

---

## ■ ライセンス
（必要に応じて後で追加）

---

## ■ 今後の予定
- CLA レイヤーの拡張
- EXMQL の最適化
- Aegis シリーズ EA の追加
