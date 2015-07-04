set -x
rm db/stocks.sqlite3
sqlite3 db/stocks.sqlite3 < db/stocks.sql
ruby import_issues_csv.rb
ruby get_stock_history.rb
ruby fill_in_indicators.rb
