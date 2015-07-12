# rubocop:disable Style/GuardClause

# 買い仕掛けルール
class LongEntryRule < Rule
  def over_ma5(_trade, stocks, issue)
    @disc = '5日移動平均線を :percent %上回ったら翌日に終値と同値で指値買い'
    if  stocks[0].close > (stocks[0].ma5 * (1.0 + @p[:percent] / 100.0))
      return { trade_type: :spot, entry_type: :limit, entry_limit_price: stocks[0].close,
               entry_expiry: @next_day, entry_size: issue.unit }
    end
  end

  def golden_cross(_trade, stocks, issue)
    @disc = 'ma5 と ma25 のゴールデンクロス'
    if (stocks[0].ma5 > stocks[0].ma25) && (stocks[1].ma5 < stocks[1].ma25)
      return { trade_type: :spot, entry_type: :limit, entry_limit_price: stocks[0].close,
               entry_expiry: @next_day, entry_size: issue.unit }
    end
  end
end

# 売り仕掛けルール
class ShortEntryRule < Rule
  def under_ma5(_trade, stocks, issue)
    @disc = '5日移動平均線を :percent %下回ったら翌日に終値と同値で指値買い'
    if stocks[0].close < (stocks[0].ma5 * (1.0 - @p[:percent] / 100.0))
      return { trade_type: :margin_selling, entry_type: :limit, entry_limit_price: stocks[0].close,
               entry_expiry: @next_day, entry_size: issue.unit }
    end
  end

  def dead_cross(_trade, stocks, issue)
    @disc = 'ma5 と ma25 のデッドクロス'
    if (stocks[0].ma5 < stocks[0].ma25) && (stocks[1].ma5 > stocks[1].ma25)
      return { trade_type: :margin_selling, entry_type: :limit, entry_limit_price: stocks[0].close,
               entry_expiry: @next_day, entry_size: issue.unit }
    end
  end
end

# 買い手仕舞いルール
class LongExitRule < Rule
  def by_execution_price(trade, _stocks, _issue)
    @disc = '約定金額の :limit_percent %上で指値、:stop_percent %下で逆指値'
    { exit_type: :limit_and_stop, exit_expiry: trade.execution_date + @p[:day],
      exit_limit_price: trade.execution_price * (1.0 + @p[:limit_percent] / 100.0),
      exit_stop_price: trade.execution_price * (1.0 - @p[:stop_percent] / 100.0) }
  end
end

# 売り手仕舞いルール
class ShortExitRule < Rule
  def by_execution_price(trade, _stocks, _issue)
    @disc = '約定金額の :limit_percent %下で指値、:stop_percent %上で逆指値'
    { exit_type: :limit_and_stop, exit_expiry: trade.execution_date + @p[:day],
      exit_limit_price: trade.execution_price * (1.0 - @p[:limit_percent] / 100.0),
      exit_stop_price: trade.execution_price * (1.0 + @p[:stop_percent] / 100.0) }
  end
end
