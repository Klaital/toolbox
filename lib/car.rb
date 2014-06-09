require 'yaml'

class Car
  attr_reader :specs
  def initialize(specs={})
    @specs = specs
    @gas_prices = YAML.load( File.join(__dir__, '..', 'config', 'gas_prices.yaml'))
  end

  def gallons_burned(miles = 100000, driving_type='city')
    return nil unless @specs.has_key?("mpg_#{driving_type}".to_sym)
    mpg = @specs[driving_mpg].to_i

    miles / mpg
  end

  def total_gas_cost(gas_type = 'regular', miles=100000, driving_type='city')
    return nil unless @gas_prices.has_key?(gas_type.downcase.to_sym)
    @gas_prices[gas_type.downcase.to_sym].to_f * miles.to_i
  end

  # Compute "fun" in terms of peak engine power per unit mass.
  # Computed here in horsepower peak per pound curb weight.
  def unit_horsepower
    hp = @specs[:peak_power]
    weight = @specs[:empty_weight]

    return nil if hp.nil? || weight.nil?

    hp.to_f / weight.to_i
  end

  # Compute how cost-effective the fun rating is for this car.
  # This is computed in terms of unit horsepower per MSRP dollar * 1000000.
  # @param features [String] Either 'min' or 'loaded'.
  def mega_funs(features='min')
    fun = unit_horsepower
    cost = @specs["msrp_#{features}"]
    return 0 if fun.nil? || cost.nil? || cost.to_i == nil

    fun.to_f * 1000000 / cost.to_f
  end

  def fun_descr(driving_type = 'city', features = 'min')
    min_cost = total_gas_cost(@stats[:gas_type].downcase, 100000, 'city') + @stats[:msrp_min].to_i
    max_cost = total_gas_cost(@stats[:gas_type].downcase, 100000, 'city') + @stats[:msrp_loaded].to_i
    "#{@stats[:year]}\t#{@stats[:make]}\t#{@stats[:model]}\t#{@stats[:variant]}\t$#{min_cost} - $#{max_cost}\t#{mega_funs('min')} - #{mega_funs('loaded')}"
  end
end


if __FILE__ == $0
  db = Mongo::MongoClient.new.db('shopping')
  coll = db['cars']
  cursor = coll.find({})
  cursor.each do |doc|
    car = Car.new(doc.to_h)
    puts car.fun_descr
end
