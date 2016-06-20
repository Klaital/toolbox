# tc_categorize_sizes_parser.rb 
require 'test/unit'
require 'logger'
require_relative '../michi/geocoder.rb'

class TcGeocoder < Test::Unit::TestCase
  def setup
	  @gc = Geocoder.new({:log => Logger.new('geocoding.log', 'daily')})
  end

  def test_encode_address_sample1
    s = '16215 NE 109th St, Redmond WA 98052'
    data = Geocoder.encode_address(s)
    assert_equal('16215+NE+109th+St,+Redmond+WA+98052', data)
  end

  def test_encode_sample1
    s = '16215 NE 109th St, Redmond WA 98052'
    data = @gc.encode(s)
    assert_equal(1, data.length)
    assert_equal('16215 NE 109th St, Redmond, WA 98052, USA', data[0]['formatted_address'])
    assert_equal(47.697831, data[0]['geometry']['location']['lat'])
    assert_equal(-122.123127, data[0]['geometry']['location']['lng'])
  end

  def test_filter_row1
    s = '2200 E MADISON ST'
    data = @gc.encode(s)
    data = @gc.filter_by_county(data)
    assert_equal(1, data.length)
    assert_equal(47.6189492, data[0]['geometry']['location']['lat']) # Original value was 47.6188545227
    assert_equal(-122.3031313, data[0]['geometry']['location']['lng']) # original value was -122.3034210205
  end

end

