require 'bundler/setup'
require 'active_record'

class Trade < ActiveRecord::Base
  establish_connection(
    'adapter' => 'sqlite3',
    'database' => 'db/trades.sqlite3',
    'timeout' => '15000'
  )
  def label
    read_attribute(:label).to_sym
  end

  def status
    read_attribute(:status).to_sym
  end

  def trade_type
    read_attribute(:trade_type).to_sym
  end

  def entry_type
    read_attribute(:entry_type).to_sym
  end

  def exit_type
    read_attribute(:exit_type).to_sym
  end

  def self.report
    puts "---------- 取引明細 ------------"
    Trade.where(label: :simulating).where(status: :liquidate).each do |trade|
      # 9984-T 売 2010.0( 1809.0, 2050.2)-> 2045.0 :  -35.0 *  100 =  -3500  -1.74%
      print trade.code
      print trade.trade_type == :margin_selling ? ' 売' : ' 買'
      print "#{'%7.1f' % trade.execution_price}(#{'%7.1f' % trade.exit_limit_price},#{'%7.1f' % trade.exit_stop_price})->#{'%7.1f' % trade.liquidation_price}"
      print " :#{'%7.1f' % trade.valuation_price}"
      print " *#{'%5.0f' % trade.execution_size}"
      print " =#{'%7.0f' % trade.valuation_amount}"
      puts " #{'%6.2f' % trade.earnings_ratio}% #{'%2.0f' % trade.days}d"
      print "          #{'%10s' % trade.execution_date.to_s} #{'%-14.14s' % trade.entry_rule} #{'%10s' % trade.liquidation_date.to_s} #{'%-14.14s' % trade.exit_rule}"
      puts
    end

    puts '---------- 最終評価 ------------'
    # 最終評価
    trade_try_count = Trade.where(label: :simulating).where(status: [:liquidate,:expired]).count
    plus_trade_count = Trade.where(label: :simulating).where(status: :liquidate).where('valuation_price > 0').count
    minus_trade_count = Trade.where(label: :simulating).where(status: :liquidate).where('valuation_price <=0').count
    plus_trade_amount = Trade.where(label: :simulating).where(status: :liquidate).where('valuation_price > 0').sum(:valuation_amount)
    minus_trade_amount = Trade.where(label: :simulating).where(status: :liquidate).where('valuation_price <=0').sum(:valuation_amount)
    average = Trade.where(label: :simulating).where(status: :liquidate).average(:earnings_ratio)

    puts "勝ち #{'%3d' % plus_trade_count}回 #{'%10.0f' % plus_trade_amount}円  仕掛け回数 #{'%3d' % trade_try_count}回"
    puts "負け #{'%3d' % minus_trade_count}回 #{'%10.0f' % minus_trade_amount}円  勝率 #{'%3.2f' % (plus_trade_count * 1.0 / (plus_trade_count + minus_trade_count) * 100.0)}%"
    puts "合計損益   #{'%10.0f' % (plus_trade_amount + minus_trade_amount)}円  平均損益率 #{'%7.2f' % average}%"

  end
end
