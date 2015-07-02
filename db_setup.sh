rm db/stocks.sqlite3
sqlite3 db/stocks.sqlite3 < db/stocks.sql
ruby import_issues_csv.rb
