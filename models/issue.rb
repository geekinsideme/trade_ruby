require 'bundler/setup'
require 'active_record'

class Issue < ActiveRecord::Base
  establish_connection(
    'adapter' => 'sqlite3',
    'database' => 'db/stocks.sqlite3',
    'timeout' => '15000'
  )

  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
  def tick(price)
    if topix100
      if price <= 1000
        0.1
      elsif price <= 3000
        0.5
      elsif price <= 5000
        0.5
      elsif price <= 30_000
        1
      elsif price <= 50_000
        5
      elsif price <= 300_000
        10
      elsif price <= 500_000
        50
      elsif price <= 3_000_000
        100
      elsif price <= 5_000_000
        500
      elsif price <= 30_000_000
        1000
      elsif price <= 50_000_000
        5000
      elsif 50_000_000 < price
        10_000
      end
    else
      if price <= 3000
        1
      elsif price <= 5000
        5
      elsif price <= 30_000
        10
      elsif price <= 50_000
        50
      elsif price <= 300_000
        100
      elsif price <= 500_000
        500
      elsif price <= 3_000_000
        1000
      elsif price <= 5_000_000
        5000
      elsif price <= 30_000_000
        10_000
      elsif price <= 50_000_000
        50_000
      elsif 50_000_000 < price
        100_000
      end
    end
  end

  # 半端な数字を上の呼び値に切り上げ
  # 半端でなければ何もしない
  def ceil(price)
    tick_size = tick(price)
    if price % tick_size == 0
      price
    else
      truncate(price) + tick_size
    end
  end

  # 半端な数字を下の呼び値に切り下げ
  # 半端でなければ何もしない
  def truncate(price)
    (price - price % tick(price)).truncate
  end

  # 何ティックか足す
  def up(price, tick = 1)
    tick.times { price += tick(price) }
    ceil(price)
  end

  # 何ティックか引く
  def down(price, tick = 1)
    tick.times { price -= tick(price) }
    truncate(price)
  end
end
