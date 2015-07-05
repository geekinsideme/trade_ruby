require_relative 'models/issue.rb'
require_relative 'models/stock.rb'
require_relative 'models/trade.rb'
require_relative 'models/array.rb'

saved_stocks_store = {}
stocks_store = {}
Issue.where(tracking: true).each do |issue|
  saved_stocks_store[issue.code] = Stock.where(code: issue.code).order(date: :desc).take(10_000)
  stocks_store[issue.code] = []
end

Trade.where(label: :simulating).update_all(label: :simulated)

catch :end_of_simulation do
  loop do
    saved_stocks_store.each_key do |code|
      stocks_store[code].unshift(saved_stocks_store[code].pop)
      throw :end_of_simulation if saved_stocks_store[code].size < 250
      stocks = stocks_store[code]

      issue = Issue.find_by(code: code)
      today = stocks[0].date
      next_day = saved_stocks_store[code][-1].date
      last_day = saved_stocks_store[code][0].date

      tick = 0
      fee = 0

      # 前日までの注文処理（エントリ）
      Trade.where(label: :simulating).where(code: code).where(status: :entry).order(created_at: :asc).each do |trade|
        executed = false
        case trade.trade_type
        when :spot, :margin_buying
          if trade.entry_type == :market
            execution_price = stocks[0].open
            executed = true
          end
          if trade.entry_type == :stop || trade.entry_type == :limit_and_stop
            if trade.entry_price > stocks[0].low
              execution_price = trade.entry_price + tick
              executed = true
            end
          end
          if trade.entry_type == :limit || trade.entry_type == :limit_and_stop
            if trade.entry_price < stocks[0].high
              execution_price = trade.entry_price
              executed = true
            end
          end
        when :margin_selling
          if trade.entry_type == :market
            execution_price = stocks[0].open
            executed = true
          end
          if trade.entry_type == :stop || trade.entry_type == :limit_and_stop
            if trade.entry_price < stocks[0].high
              execution_price = trade.entry_price - tick
              executed = true
            end
          end
          if trade.entry_type == :limit || trade.entry_type == :limit_and_stop
            if trade.entry_price > stocks[0].low
              execution_price = trade.entry_price
              executed = true
            end
          end
          fee = -fee
        end
        if executed
          # 注文確定
          trade.execution_date = stocks[0].date
          trade.execution_size = trade.entry_size
          trade.execution_price = execution_price
          trade.execution_fee = fee
          trade.execution_amount = trade.entry_size * execution_price + fee
          trade.status = :executed
          trade.save
          # puts '注文確定'
          # p trade
        elsif trade.entry_expiry <= today
          # 注文失効
          trade.status = :expired
          trade.save
          # puts '注文失効'
          # p trade
        end
      end

      # 手仕舞い注文
      Trade.where(label: :simulating).where(code: code).where(status: :exit).order(created_at: :asc).each do |trade|
        executed = false
        case trade.trade_type
        when :spot, :margin_buying
          if trade.exit_type == :market
            execution_price = stocks[0].open
            executed = true
          end
          if trade.exit_type == :stop || trade.exit_type == :limit_and_stop
            if trade.exit_price > stocks[0].low
              execution_price = stocks[0].low
              executed = true
            end
          end
          if trade.exit_type == :limit || trade.exit_type == :limit_and_stop
            if trade.exit_price < stocks[0].high
              execution_price = trade.exit_price
              executed = true
            end
          end
        when :margin_selling
          if trade.exit_type == :market
            execution_price = stocks[0].open
            executed = true
          end
          if trade.exit_type == :stop || trade.exit_type == :limit_and_stop
            if trade.exit_price < stocks[0].high
              execution_price = stocks[0].high
              executed = true
            end
          end
          if trade.exit_type == :limit || trade.exit_type == :limit_and_stop
            if trade.exit_price > stocks[0].low
              execution_price = trade.exit_price
              executed = true
            end
          end
          fee = -fee
        end
        if !executed && trade.entry_expiry <= today
          # puts '強制執行'
          execution_price = stocks[0].open
          executed = true
        end

        if executed
          # 注文確定
          trade.liquidation_date = stocks[0].date
          trade.liquidation_price = execution_price
          trade.liquidation_fee = fee
          trade.liquidation_amount = trade.entry_size * execution_price - fee
          trade.valuation_price = trade.trade_type == :margin_selling ? trade.execution_price-execution_price : execution_price-trade.execution_price
          trade.valuation_amount = trade.valuation_price * trade.entry_size - fee
          trade.earnings_ratio = trade.valuation_amount / trade.execution_amount * 100.0
          trade.status = :liquidate
          trade.save
          # puts '手仕舞い確定'
          # p trade
        end
      end

      # 仕掛け　（すでにこの銘柄に仕掛けていれば、あらたに仕掛けない）
      unless Trade.where(label: :simulating).where(code: code).where(status: [:entry, :executed, :holding, :exit]).exists?
        entry = {}
        # 買いルール適用
        # 5日移動平均線を10%上回ったら翌日に成り行き買い
        if stocks[0].close > stocks[0].ma5 * 1.1
          entry = { trade_type: :spot, entry_type: :limit, entry_price: stocks[0].close, entry_expiry: next_day, entry_size: issue.unit }
        end
        # 売りルール適用
        # 5日移動平均線を10%下回ったら翌日に成り行き売り
        if stocks[0].close < stocks[0].ma5 * 0.9
          entry = { trade_type: :margin_selling, entry_type: :limit, entry_price: stocks[0].close, entry_expiry: next_day, entry_size: issue.unit }
        end
        if entry.size > 0
          entry.merge!(label: :simulating, code: code, status: :entry, entry_date: next_day)
          new_trade = Trade.new (entry)
          new_trade.save
          # puts '仕掛け'
          # p new_trade
        end
      end
      # 手仕舞い
      Trade.where(label: :simulating).where(code: code).where(status: [:executed, :holding, :exit]).each do |trade|
        # ルール適用
        exit = { exit_expiry: last_day }
        case trade.trade_type
        when :spot,:margin_buying
          exit = { exit_type: :limit_and_stop, exit_expiry: nil, exit_price: trade.execution_price*1.05 ,exit_price2: trade.execution_price*0.98 }
        when :margin_selling
          exit = { exit_type: :limit_and_stop, exit_expiry: nil, exit_price: trade.execution_price*0.95 ,exit_price2: trade.execution_price*1.02 }
        end
        exit.merge!(status: :exit, exit_date: next_day)
        exit[:last_price] = stocks[0].close
        exit[:the_day_before] = stocks[0].close - stocks[1].close
        exit[:valuation_price] = trade.trade_type == :margin_selling ? trade.execution_price-stocks[0].close : stocks[0].close-trade.execution_price
        trade.update(exit)
      end
      # 銘柄評価
    end # 銘柄

    # 仕掛けフィルタリング
    # 手仕舞いフィルタリング
    # オーダー発行
    # 日次評価
  end # 日次
end

Trade.where(label: :simulating).where(status: :liquidate).each do |trade|
  print trade.code
  print trade.trade_type == :margin_selling ? " 売" : " 買"
  print " #{'%8.1f' % trade.execution_price} -> #{'%8.1f' % trade.liquidation_price}"
  print " : #{'%8.1f' % trade.valuation_price}"
  print " * #{'%5.0f' % trade.execution_size}"
  print " = #{'%10.0f' % trade.valuation_amount}"
  puts " #{'%7.2f' % trade.earnings_ratio}%"
end


puts "---------- 最終評価 ------------"
# 最終評価
plus_trade_count = Trade.where(label: :simulating).where(status: :liquidate).where("valuation_price > 0").count
minus_trade_count = Trade.where(label: :simulating).where(status: :liquidate).where("valuation_price <=0").count
plus_trade_amount = Trade.where(label: :simulating).where(status: :liquidate).where("valuation_price > 0").sum(:valuation_amount)
minus_trade_amount = Trade.where(label: :simulating).where(status: :liquidate).where("valuation_price <=0").sum(:valuation_amount)
average = Trade.where(label: :simulating).where(status: :liquidate).average(:earnings_ratio)

puts "勝ち #{'%3d' % plus_trade_count}回 #{'%10.0f' % plus_trade_amount}円"
puts "負け #{'%3d' % minus_trade_count}回 #{'%10.0f' % minus_trade_amount}円  勝率 #{'%3.2f' % (plus_trade_count*1.0/(plus_trade_count+minus_trade_count)*100.0)}%"
puts "合計損益   #{'%10.0f' % (plus_trade_amount+minus_trade_amount)}円  平均損益率 #{'%7.2f' % average}%"
