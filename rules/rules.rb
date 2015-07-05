# 買い仕掛けルール
class LongEntryRule < Rule
  def over_ma5(trade, stocks, issue)
    @disc = "5日移動平均線を :percent %上回ったら翌日に終値と同値で指値買い"
    if stocks[0].close > stocks[0].ma5 * (1.0+@p[:percent]/100.0)
      entry = { trade_type: :spot, entry_type: :limit, entry_price: stocks[0].close, entry_expiry: @next_day, entry_size: issue.unit }
    end
    entry
  end
end

# 売り仕掛けルール
class ShortEntryRule < Rule
  def under_ma5(trade, stocks, issue)
    @disc = "5日移動平均線を :percent %下回ったら翌日に終値と同値で指値買い"
    if stocks[0].close < stocks[0].ma5 * (1.0-@p[:percent]/100.0)
      entry = { trade_type: :margin_selling, entry_type: :limit, entry_price: stocks[0].close, entry_expiry: @next_day, entry_size: issue.unit }
    end
    entry
  end
end

# 買い手仕舞いルール
class LongExitRule < Rule
  def exit_on_execution_price(trade, stocks, issue)
    @disc = "約定金額の :limit_percent %上で指値、:stop_percent %下で逆指値"
    { exit_type: :limit_and_stop, exit_expiry: (@today+@p[:day]).to_s, exit_price: trade.execution_price * (1.0+@p[:limit_percent]/100.0), exit_price2: trade.execution_price * (1.0-@p[:stop_percent]/100.0) }
  end
end

# 売り手仕舞いルール
class ShortExitRule < Rule
  def exit_on_execution_price(trade, stocks, issue)
    @disc = "約定金額の :limit_percent %下で指値、:stop_percent %上で逆指値"
    { exit_type: :limit_and_stop, exit_expiry: (@today+@p[:day]).to_s, exit_price: trade.execution_price * (1.0-@p[:limit_percent]/100.0), exit_price2: trade.execution_price * (1.0+@p[:stop_percent]/100.0) }
  end
end
