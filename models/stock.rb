require 'bundler/setup'
require 'active_record'

class Stock < ActiveRecord::Base
  establish_connection(
    'adapter' => 'sqlite3',
    'database' => 'db/stocks.sqlite3',
    'timeout' => '15000'
  )
  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

  # 買いオペレーション
  def self.buy(limit, stop, stock)
    if !limit && !stop
      # 成り行き
      return [stock.open, 'market/open']
    end
    if limit && stop
      if limit < stock.low
        return [nil, nil] if stop > stock.high
        return [stock.high, 'stop/high']
      end
      return [limit, 'limit/limit'] if limit < stock.open
      return [stock.open, 'limit/open']
    end
    if limit
      # 指値　（指定価格より安ければ約定）
      return [nil, nil] if limit < stock.low
      return [limit, 'limit/limit'] if limit < stock.open
      return [stock.open, 'limit/open']
    end
    if stop
      # 逆指値　（指定価格より高ければ、成り行き）
      return [nil, nil] if stop > stock.high
      return [stock.high, 'stop/high']
    end
  end
  # 売りオペレーション
  def self.sell(limit, stop, stock)
    if !limit && !stop
      # 成り行き
      return [stock.open, 'market/open']
    end
    if limit && stop
      if limit > stock.high
        return [nil, nil] if stop < stock.low
        return [stock.low, 'stop/low']
      end
      return [limit, 'limit/limit'] if limit > stock.open
      return [stock.open, 'limit/open']
    end
    if limit
      # 指値　（指定価格より高ければ約定）
      return [nil, nil] if limit > stock.high
      return [limit, 'limit/limit'] if limit > stock.open
      return [stock.open, 'limit/open']
    end
    if stop
      # 逆指値　（指定価格より安ければ、成り行き）
      return [nil, nil] if stop < stock.low
      return [stock.low, 'stop/low']
    end
  end
end
