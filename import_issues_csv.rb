require "csv"
require_relative "models/issue.rb"

CSV.open( "db/stocks.csv","r",headers: :first_row,encoding: "UTF-8" ).each do |row|
  if issue = Issue.find_by( code: row["code"])
    issue.update( row.to_hash )
  else
    Issue.create( row.to_hash )
  end
end
