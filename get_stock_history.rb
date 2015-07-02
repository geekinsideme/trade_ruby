require "csv"
require "open-uri"
require "date"

require_relative "models/issue.rb"
require_relative "models/stock.rb"

ActiveRecord::Base.establish_connection(
    "adapter" => "sqlite3",
    "database" => "db/stocks.sqlite3",
    "timeout" => "15000"
  )

ARGV.each do |code|
  if !Issue.find_by(code: code)
    puts "#{code} is not found in Issue"
    abort
  end

  File::delete("tmp/stock_history.csv") if File::exists?("tmp/stock_history.csv")

  (Date::today.year).downto(2007).each do |year|
    File.open("tmp/stock_history.csv", "a") do |saved_file|
      open("http://k-db.com/stocks/#{code}?year=#{year}&download=csv", "r") do |read_file|
        saved_file.write(read_file.read)
      end
    end
  end

  File.open("tmp/stock_history.csv","r",encoding: "SJIS") do |saved_file|
    saved_file.each_line do |line|
      date,open,high,low,close,trading_volume,trading_value = line.split(",")
      next unless date =~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/
      stock = Stock.find_or_initialize_by({code: code,date: date})
      stock.open = open
      stock.high = high
      stock.low = low
      stock.close = close
      stock.trading_volume = trading_volume
      stock.trading_value = trading_value
      stock.save
    end
  end

  Issue.find_by(code: code).update tracking: true
end
