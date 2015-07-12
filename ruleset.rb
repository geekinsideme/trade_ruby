[
  { klass: :LongEntryRule, rule: :over_ma5, percent: 15 },
  { klass: :LongEntryRule, rule: :golden_cross },
  { klass: :LongExitRule, rule: :by_execution_price, day: 14, limit_percent: 10, stop_percent: 2 },
  { klass: :ShortEntryRule, rule: :under_ma5, percent: 15 },
  { klass: :ShortEntryRule, rule: :dead_cross },
  { klass: :ShortExitRule, rule: :by_execution_price, day: 14, limit_percent: 10, stop_percent: 2 },
  { klass: :Dummy }
]
