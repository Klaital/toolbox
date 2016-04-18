# position.rb - Contains logic describing a stock market position.
# Given information about a purchase, it can be used to compute current value, gains/losses, etc.
require 'time'
require 'date'
require 'net/http'
require 'uri'
require 'json'

class Position
  attr_reader :cur_price, :cur_price_timestamp
  def initialize(conf={})
    @purchase_date = conf.has_key?(:purchase_date) ? (Date.parse(conf[:purchase_date])) : Date.today
    @symbol        = conf[:symbol]
    @quantity      = conf[:quantity].to_i
    @buy_price     = conf[:buy_price].to_i / 100.0
    @commission    = conf[:commission].to_i / 100.0

  end

  def to_s
    "#{@purchase_date}\t#{@symbol}\t#{@quantity}\t#{@buy_price}\t#{@commission}\t#{current_price}\t#{current_value}\t#{total_gain}"
  end

  def current_price
    # Don't waste any time returning a useful error if no symbol has been set
    return 0 if @symbol.nil? || @symbol == ''

    # Use the previously fetched value if it's fairly new 
    # (i.e., probably during the same thread's execution)
    timeout_secs = 5
    if Time.now.to_i - timeout_secs < @cur_price_timestamp.to_i
      warn "Using cached price quote"
      return @cur_price
    end

    uri = 'http://finance.yahoo.com/webservice/v1/symbols/$symbol/quote?format=json'.gsub('$symbol', @symbol)
    uri = URI.parse(uri)

    response = Net::HTTP.get_response(uri)
    if response.code == '200'
      payload = JSON.parse(response.body)
      price = payload['list']['resources'][0]['resource']['fields']['price'].to_f
      price_rounded = (price * 100).round / 100.0

    else
      warn "Unable to fetch prices for #{@symbol} using GET #{uri}"
      warn "> #{response.code} #{response.body}"
      return 0
    end
  end

  # Computes the current value 
  def current_value
    (current_price * @quantity * 100).round / 100.0
  end

  # Computes the initial value of the purchase
  def initial_value
    (@buy_price * @quantity * 100).round / 100.0
  end

  # Computes the delta between purchase value and current value
  def total_gain
    (((current_value - initial_value) - @commission) * 100).round / 100.0
  end
end

############################
#### MAIN - for testing ####
############################
if __FILE__ == $0
  # 
  # Pull the list of positions from a local mongo collection
  #
  require 'mongo'
  db = Mongo::MongoClient.new( 'localhost', 27017 ).db( 'stocks' )
  position_table = db[ 'positions' ]
  position_list = position_table.find()
  
  positions = []
  # Reformat the entries to use symbols rather than string keys.
  position_list.each do |doc|
    p = Position.new({
      :purchase_date => doc['purchase_date'],
      :symbol        => doc['symbol'],
      :quantity      => doc['quantity'],
      :buy_price     => doc['buy_price'],
      :commission    => doc['commission']
    })
    positions.push(p)
  end
  
  # TODO: query web API for current stock values
  # TODO: compute current value of each position

  # Show the header row
  puts "Buy Date\tStock\tQty\tBuy $\tComm.\tCur. $\t$Cur. Value\tGain"

  # Fill in the CSV rows for each position
  total_value = 0
  total_gain  = 0
  positions.each do |p| 
    puts p.to_s
    total_value += p.current_value
    total_gain += p.total_gain
  end

  # Show the summary stats
  puts "\n------- Summary ----------"
  puts "Total Value: #{total_value}"
  puts "Total Gain:  #{total_gain}"
end

 