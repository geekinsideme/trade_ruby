-- 株価情報テーブル
CREATE TABLE IF NOT EXISTS stocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date DATE, -- 日付
  code TEXT, -- コード
  open REAL, -- 始値
  high REAL, -- 高値
  low REAL, -- 安値
  close REAL, -- 終値
  trading_volume REAL, -- 出来高
  trading_value REAL, -- 売買代金
  created_at,
  updated_at
);
-- 　インデックス定義
CREATE INDEX dateindexonstocks ON stocks(date);
CREATE INDEX codeindexonstocks ON stocks(code);
CREATE INDEX codedateindexonstocks ON stocks(code,date);
--   追加カラム（株価指標）
ALTER TABLE stocks ADD COLUMN ma5 REAL; -- 5日移動平均
ALTER TABLE stocks ADD COLUMN ma25 REAL; -- 25日移動平均
ALTER TABLE stocks ADD COLUMN ma75 REAL; -- 75日移動平均

-- 銘柄情報テーブル
CREATE TABLE IF NOT EXISTS issues (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT, -- コード
  market TEXT, -- 市場
  issue TEXT, -- 銘柄
  issue_short TEXT, -- 銘柄（短縮）
  industry TEXT, -- 業種
  unit REAL, -- 単元株式数
  info TEXT, -- 付帯情報
  topix100 BOOLEAN, -- TOPIX100構成銘柄
  tracking BOOLEAN, -- 更新フラグ
  created_at,
  updated_at
);
-- 　インデックス定義
CREATE INDEX codeindexonissues ON issues(code);
CREATE INDEX trackingindexonissues ON issues(tracking);
