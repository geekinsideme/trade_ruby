require_relative 'indicator.rb'

class Array
  # 合計
  def sum
    inject(:+)
  end

  # 平均
  def average
    sum.to_f / size
  end

  include Indicator
end
