require 'yaml'
require 'mongo'

class Car
  attr_reader :specs
  def initialize(specs={})
    @specs = specs
    @gas_prices = YAML.load_file( File.join(__dir__, '..', 'config', 'gas_prices.yaml') )
    puts @gas_prices if $DEBUG
  end

  def gallons_burned(miles = 100000, driving_type='city')
    return nil unless @specs.has_key?("mpg_#{driving_type}")
    mpg = @specs["mpg_#{driving_type}"].to_i

    miles / mpg
  end

  def total_gas_cost(gas_type = 'regular', miles=100000, driving_type='city')
    return nil unless @gas_prices.has_key?(gas_type.downcase.to_sym)
    @gas_prices[gas_type.downcase.to_sym].to_f * miles.to_i
  end

  # Compute "fun" in terms of peak engine power per unit mass.
  # Computed here in horsepower peak per pound curb weight.
  def unit_horsepower
    hp = @specs['peak_power']
    weight = @specs['empty_weight']

    return nil if hp.nil? || weight.nil?

    hp.to_f / weight.to_i
  end

  # Compute how cost-effective the fun rating is for this car.
  # This is computed in terms of unit horsepower per TCO dollar * 1000000.
  # @param features [String] Either 'min' or 'loaded'.
  def mega_funs(features='min', gas_type='regular', miles = 100000)
    fun = unit_horsepower
    base_cost = @specs["msrp_#{features}"]
    gas_cost = total_gas_cost(gas_type, miles, 'city')
    return 0 if fun.nil? || base_cost.nil? || base_cost.to_i == 0 || base_cost == 'NULL'

    fun.to_f * 1000000 / (base_cost.to_f + gas_cost)
  end

  def fun_descr(driving_type = 'city', features = 'min')
    gas_type = @specs['gas_type'].downcase
    puts "GasType=#{gas_type}" if $DEBUG
    gas_cost = total_gas_cost(gas_type, 100000, driving_type)
    puts "TotalGasCost=#{gas_cost}" if $DEBUG
    min_cost = gas_cost + @specs['msrp_min'].to_i
    max_cost = gas_cost + @specs['msrp_loaded'].to_i
    "#{@specs['year']}\t#{@specs['make']}\t#{@specs['model']}\t#{@specs['variant']}\t$#{min_cost} - $#{max_cost}\t#{mega_funs('min')} - #{mega_funs('loaded')}"
  end
end


if __FILE__ == $0
  db = Mongo::MongoClient.new.db('shopping')
  coll = db['cars']
  cursor = coll.find({})
  cursor.each do |doc|
    data = doc.to_h
    puts data if $DEBUG
    car = Car.new(data)
    puts car.specs.nil? if $DEBUG
    puts car.fun_descr
  end
end

