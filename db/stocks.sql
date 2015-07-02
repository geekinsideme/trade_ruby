-- 株価情報テーブル
CREATE TABLE IF NOT EXISTS stocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date DATE, -- 日付
  code TEXT, -- コード
  open NUMERIC, -- 始値
  high NUMERIC, -- 高値
  low NUMERIC, -- 安値
  close NUMERIC, -- 終値
  trading_volume NUMERIC, -- 出来高
  trading_value NUMERIC, -- 売買代金
  created_at,
  updated_at
);
-- 　インデックス定義
CREATE INDEX dateindexonstocks ON stocks(date);
CREATE INDEX codeindexonstocks ON stocks(code);
CREATE INDEX codedateindexonstocks ON stocks(code,date);
--   追加カラム（株価指標）
ALTER TABLE stocks ADD COLUMN ma5 NUMERIC; -- 5日移動平均
ALTER TABLE stocks ADD COLUMN ma25 NUMERIC; -- 25日移動平均

-- 銘柄情報テーブル
CREATE TABLE IF NOT EXISTS issues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT, -- コード
  market TEXT, -- 市場
  issue TEXT, -- 銘柄
  issue_short TEXT, -- 銘柄（短縮）
  industry TEXT, -- 業種
  unit NUMERIC, -- 単元株式数
  info TEXT, -- 付帯情報
  created_at,
  updated_at
);
-- 　インデックス定義
CREATE INDEX codeindexonissues ON issues(code);
