require 'date'

# We have this much in my retirement portfolio already
initial_investment = 98_000
# We saw growth of my stock portfolio of 7-9% in 2016
growth_rate = 0.08

# Assume an additional investment of $40,000 per year
additional_investment = 40_000

# Death age
death_age = 100

# Spending rate after retirement. Our salary, essentially
spending_rate = 100_000

# Retirement Target (i.e., I think we can retire when our account reaches this number)
retirement_target = 5_000_000

# Determine how much money was gained in one year
def grow_one_year(starting_balance, growth_rate)
  starting_balance * (1.0 + growth_rate)
end

ending_balance = initial_investment
puts "Year\tEnding Balance\tRetire?"
40.times do |i|
  ending_balance = grow_one_year(ending_balance + additional_investment, growth_rate)
  can_retire = ending_balance >= retirement_target
  puts "#{Date.today.year + i + 1}\t$#{ending_balance.round(2)}\t#{can_retire}"
end 


