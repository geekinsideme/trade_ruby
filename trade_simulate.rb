require_relative 'models/issue.rb'
require_relative 'models/stock.rb'
require_relative 'models/trade.rb'
require_relative 'models/rule.rb'
require_relative 'models/array.rb'
require_relative 'rules/rules.rb'

saved_stocks_store = {}
stocks_store = {}
Issue.where(tracking: true).each do |issue|
  saved_stocks_store[issue.code] = Stock.where(code: issue.code).order(date: :desc).take(10_000)
  stocks_store[issue.code] = []
end

Trade.where(label: :simulating).update_all(label: :simulated)


ruleset = eval(File.open("ruleset.rb").read)
puts "---------- ルール --------------"
ruleset.each do |rule|
  p rule
end


catch :end_of_simulation do
  loop do
    saved_stocks_store.each_key do |code|
      throw :end_of_simulation if saved_stocks_store[code].size <1
      stocks_store[code].unshift(saved_stocks_store[code].pop)
      next if stocks_store[code].size <250
      stocks = stocks_store[code]

      issue = Issue.find_by(code: code)
      today = stocks[0].date
      next_day = saved_stocks_store[code][-1].date rescue today
      last_day = saved_stocks_store[code][0].date rescue today

      tick = 0
      fee = 0

      # 前日までの注文処理（仕掛け）
      Trade.where(label: :simulating).where(code: code).where(status: :entry).order(created_at: :asc).each do |trade|
        execution_reason = nil
        case trade.trade_type
        when :spot, :margin_buying
          case trade.entry_type
          when :market
            execution_price,execution_reason = Stock.buy nil,nil,stocks[0]
          when :limit
            execution_price,execution_reason = Stock.buy trade.entry_limit_price,nil,stocks[0]
          when :stop
            execution_price,execution_reason = Stock.buy nil,trade.entry_stop_price,stocks[0]
          when :limit_and_stop
            execution_price,execution_reason = Stock.buy trade.entry_limit_price,trade.entry_stop_price,stocks[0]
          end
        when :margin_selling
          case trade.entry_type
          when :market
            execution_price,execution_reason = Stock.sell nil,nil,stocks[0]
          when :limit
            execution_price,execution_reason = Stock.sell trade.entry_limit_price,nil,stocks[0]
          when :stop
            execution_price,execution_reason = Stock.sell nil,trade.entry_stop_price,stocks[0]
          when :limit_and_stop
            execution_price,execution_reason = Stock.sell trade.entry_limit_price,trade.entry_stop_price,stocks[0]
          end
          fee = -fee
        end
        if execution_reason
          # 注文確定
          trade.execution_date = stocks[0].date
          trade.execution_size = trade.entry_size
          trade.execution_price = execution_price
          trade.execution_reason = execution_reason
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

      # 前日までの注文処理（手仕舞い）
      Trade.where(label: :simulating).where(code: code).where(status: :exit).order(created_at: :asc).each do |trade|
        execution_reason = nil
        case trade.trade_type
        when :spot, :margin_buying
          case trade.exit_type
          when :market
            execution_price,execution_reason = Stock.sell nil,nil,stocks[0]
          when :limit
            execution_price,execution_reason = Stock.sell trade.exit_limit_price,nil,stocks[0]
          when :stop
            execution_price,execution_reason = Stock.sell nil,trade.exit_stop_price,stocks[0]
          when :limit_and_stop
            execution_price,execution_reason = Stock.sell trade.exit_limit_price,trade.exit_stop_price,stocks[0]
          end
        when :margin_selling
          case trade.exit_type
          when :market
            execution_price,execution_reason = Stock.buy nil,nil,stocks[0]
          when :limit
            execution_price,execution_reason = Stock.buy trade.exit_limit_price,nil,stocks[0]
          when :stop
            execution_price,execution_reason = Stock.buy nil,trade.exit_stop_price,stocks[0]
          when :limit_and_stop
            execution_price,execution_reason = Stock.buy trade.exit_limit_price,trade.exit_stop_price,stocks[0]
          end
          fee = -fee
        end

        if !execution_reason && trade.exit_expiry < today
          # puts '強制執行'
          execution_price = stocks[0].open
          execution_reason = "expired"
        end
        if execution_reason
          # 注文確定
          trade.liquidation_date = stocks[0].date
          trade.liquidation_price = execution_price
          trade.liquidation_reason = execution_reason
          trade.liquidation_fee = fee
          trade.liquidation_amount = trade.entry_size * execution_price - fee
          trade.valuation_price = trade.trade_type == :margin_selling ? trade.execution_price - execution_price : execution_price - trade.execution_price
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
        new_trade = Trade.new
        entry = {}
        # 買いルール適用
        ruleset.each do |rule|
          next unless rule[:klass] == :LongEntryRule
          instance = LongEntryRule.new rule.merge({today: today,next_day: next_day})
          if entry = instance.send(rule[:rule], new_trade, stocks, issue)
            entry.merge!(entry_rule: rule[:rule])
            break
          else
            entry = {}
          end
        end
        if entry.size > 0
          entry.merge!(label: :simulating, code: code, status: :entry, entry_date: today)
          new_trade.update entry
          # puts '仕掛け'
          # p new_trade
        end
        # 売りルール適用
        ruleset.each do |rule|
          next unless rule[:klass] == :ShortEntryRule
          instance = ShortEntryRule.new rule.merge({today: today,next_day: next_day})
          if entry = instance.send(rule[:rule], new_trade, stocks, issue)
            entry.merge!(entry_rule: rule[:rule])
            break
          else
            entry = {}
          end
        end
        if entry.size > 0
          entry.merge!(label: :simulating, code: code, status: :entry, entry_date: today)
          new_trade.update entry
          # puts '仕掛け'
          # p new_trade
        end
      end
      # 手仕舞い
      Trade.where(label: :simulating).where(code: code).where(status: [:executed, :holding, :exit]).each do |trade|
        # ルール適用
        exit = { exit_expiry: last_day-1 }
        case trade.trade_type
        when :spot, :margin_buying
          ruleset.each do |rule|
            next unless rule[:klass] == :LongExitRule
            instance = LongExitRule.new rule.merge({today: today,next_day: next_day})
            if exit = instance.send(rule[:rule], trade, stocks, issue)
              exit.merge!(exit_rule: rule[:rule])
              break
            end
          end
        when :margin_selling
          ruleset.each do |rule|
            next unless rule[:klass] == :ShortExitRule
            instance = ShortExitRule.new rule.merge({today: today,next_day: next_day})
            if exit = instance.send(rule[:rule], trade, stocks, issue)
              exit.merge!(exit_rule: rule[:rule])
              break
            end
          end
        end
        exit[:exit_expiry] = last_day-1 if exit[:exit_expiry] > last_day-1
        exit.merge!(status: :exit)
        exit[:days] = trade.days ? trade.days + 1 : 1
        exit[:last_price] = stocks[0].close
        exit[:the_day_before] = stocks[0].close - stocks[1].close
        exit[:valuation_price] = trade.trade_type == :margin_selling ? trade.execution_price - stocks[0].close : stocks[0].close - trade.execution_price
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
Trade.report

