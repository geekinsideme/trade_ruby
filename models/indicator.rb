module Indicator
  def ma5
    take(5).map(&:close).average
  end

  def ma25
    take(25).map(&:close).average
  end

  def ma75
    take(75).map(&:close).average
  end
end

class Array
  include Indicator
end
