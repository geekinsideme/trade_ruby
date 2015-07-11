-- 取引情報テーブル
CREATE TABLE IF NOT EXISTS trades (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  label TEXT, -- データ種別 :real :simulating :simulated
  code TEXT, -- コード
  status TEXT, -- 状況 :entry :executed :expired :holding :exit :liquidate :disabled :canceled
  trade_type TEXT, -- 種別  :spot 現物 :margin_buying 信用買い :margin_selling 信用売り
  entry_date DATE, -- 注文日付
  entry_type TEXT, -- 注文種別 :market 成行 :limit 指値 :stop 逆指値 :limit_and_stop OTO
  entry_expiry DATE, -- 注文有効期限
  entry_size REAL, -- 注文数量
  entry_limit_price REAL, -- 注文単価
  entry_stop_price REAL, -- 注文単価
  entry_rule TEXT, -- 適用ルール
  execution_date DATE, --　約定日付
  execution_size REAL, -- 約定数量
  execution_price REAL, -- 約定単価
  execution_reason TEXT, -- 約定理由
  execution_fee REAL, -- 約定手数料
  execution_amount REAL, -- 約定金額(手数料含む)
  last_price REAL, -- 現在価格
  days INTEGER, -- 保有日数
  the_day_before REAL, -- 前日比 (%)
  valuation_price REAL, -- 評価損益（単価）
  valuation_amount REAL, -- 評価損益額
  earnings_ratio REAL, -- 評価損益率（％）
  exit_date DATE, -- 手仕舞い注文日付
  exit_type TEXT, -- 手仕舞い注文種別 :market 成行 :limit 指値 :stop 逆指値 :limit_and_stop OTO
  exit_expiry DATE, -- 手仕舞い注文有効期限（強制執行）
  exit_limit_price REAL, -- 手仕舞い注文単価
  exit_stop_price REAL, -- 手仕舞い注文単価
  exit_rule TEXT, -- 適用ルール
  liquidation_date DATE, --　清算日付
  liquidation_price REAL, -- 清算単価
  liquidation_reason TEXT, -- 手仕舞い理由
  liquidation_fee REAL, -- 清算手数料
  liquidation_amount REAL, -- 清算金額(手数料を引いたもの)
  created_at,
  updated_at
);
-- 　インデックス定義
CREATE INDEX labelindexontrades ON trades(label);
CREATE INDEX codeindexontrades ON trades(code);
CREATE INDEX statusindexontrades ON trades(status);
CREATE INDEX entry_dateindexontrades ON trades(entry_date);
--   View定義
CREATE VIEW simulating AS SELECT * FROM trades WHERE label="simulating" ORDER BY entry_date DESC;
