require_relative 'models/issue.rb'
require_relative 'models/stock.rb'
require_relative 'models/array.rb'
require_relative 'models/indicator.rb'

Issue.where(tracking: true).each do |issue|
  saved_stocks = Stock.where(code: issue.code).order(date: :desc).take(10_000)

  Stock.attribute_names.each do |column|
    next if %w(id date code open high low close trading_volume trading_value created_at updated_at).include?(column)
    indicator = column.to_sym

    stocks = saved_stocks.clone
    while stocks.size > 0
      break if stocks[0][indicator] # 計算済み
      stocks[0][indicator] = stocks.send(indicator)
      stocks.shift
    end
  end
  saved_stocks.each do |row|
    row.save if row.changed?
  end
end
