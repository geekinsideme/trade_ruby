require 'open-uri'
require 'date'

require_relative 'models/issue.rb'
require_relative 'models/stock.rb'

ActiveRecord::Base.establish_connection(
  'adapter' => 'sqlite3',
  'database' => 'db/stocks.sqlite3',
  'timeout' => '15000'
)

def get_current_stock(date)
  File.delete('tmp/current_stock.csv') if File.exist?('tmp/current_stock.csv')

  File.open('tmp/current_stock.csv', 'w') do |saved_file|
    puts "getting current stock from k-db.com ( #{date} ) ..."
    open("http://k-db.com/stocks/#{date}?download=csv", 'r') do |read_file|
      saved_file.write(read_file.read)
    end
  end

  File.open('tmp/current_stock.csv', 'r', encoding: 'SJIS').each_line do |line|
    line = line.encode('UTF-8', 'Shift_JIS').strip.gsub(/年/, '-').gsub(/月/, '-').gsub(/日/, '')
    if Date.parse(line) == Date.parse(date)
      break
    else
      return()
    end
  end

  puts "importing current stock to database ( #{date} ) ..."
  File.open('tmp/current_stock.csv', 'r', encoding: 'SJIS') do |saved_file|
    saved_file.each_line do |line|
      # コード,市場,銘柄名,業種,始値,高値,安値,終値,出来高,売買代金
      code, _market, _issue, _industry, open, high, low, close, trading_volume, trading_value = line.split(',')
      next unless open =~ /[0-9.]+/
      next unless Issue.find_by(code: code, tracking: true)
      stock = Stock.find_or_initialize_by(code: code, date: date)
      stock.open = open
      stock.high = high
      stock.low = low
      stock.close = close
      stock.trading_volume = trading_volume
      stock.trading_value = trading_value
      stock.save
    end
  end
  puts "importing finished ( #{date} )"
end

if ARGV.count == 0
  max_date = Stock.maximum(:date).to_s
  (max_date..Date.today.to_s).each do |date|
    date_ary = date.split(/-/)
    if Date.valid_date?(date_ary[0].to_i, date_ary[1].to_i, date_ary[2].to_i)
      get_current_stock date
    end
  end
else
  ARGV.each do |date|
    get_current_stock date
  end
end
