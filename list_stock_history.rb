require_relative 'models/stock.rb'

from_date = Date.parse(ARGV[1])-7
to_date = Date.parse(ARGV[1])+14


Stock.where(code: ARGV[0]).where("? <= date AND date <= ?",from_date,to_date).each do |row|
  if row.date.to_s == ARGV[1]
    print "----------"
    Stock.attribute_names.each do |column|
      next if %w(id date code trading_volume trading_value created_at updated_at).include?(column)
      print ' %-6.6s' % column
    end
    puts
  end
  print row[:date].to_s
  Stock.attribute_names.each do |column|
    next if %w(id date code trading_volume trading_value created_at updated_at).include?(column)
    print ('%7.1f' % row[column]).to_s
  end
  puts
end
