class Rule
  def initialize(params)
    @p = params
    @today = params[:today]
    @next_day = params[:next_day]
  end
end
