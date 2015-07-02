require "bundler/setup"
require "active_record"

class Stock < ActiveRecord::Base
  establish_connection(
    "adapter" => "sqlite3",
    "database" => "db/stocks.sqlite3"
  )
end
