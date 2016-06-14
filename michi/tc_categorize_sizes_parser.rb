# tc_categorize_sizes_parser.rb 
require 'test/unit'
require_relative './categorize_sizes.rb'

class TcSizeParser < Test::Unit::TestCase
  def setup
    @sizer = SizeCategorizer.new#({:logger => Logger.new('testing.log', 'hourly')})
  end

  def test_parse_row2
    s = 'Land Use Application to allow one, 6-story building containing 102 assisted living units and 1,445 sq. ft. of retail space.  Parking for 37 vehicles to be provided below grade.  Project includes 10,000 cu. yds. of grading. Existing structure to be demolished.'
    data = @sizer.parse_line(s, 2)
    assert_equal(1, data[:sqft_list].length)
    assert_equal(1445, data[:sqft_list][0])
    assert_equal(1445, data[:sqft_total])
    assert_equal(102, data[:units])
  end

  def test_parse_row3
    s = 'Land Use Application to install a 10 ft. by 18 ft. parking pad for existing single family residence and driveway to street access.'
    data = @sizer.parse_line(s, 3)
    assert_equal(0, data[:sqft_list].length)
    assert_equal(0, data[:sqft_total])
    assert_equal(0, data[:units])
  end

  def test_parse_row4
    # We want to skip "additions".
    s = 'Land use application to allow 325 square foot addition to a single family residence.  Project includes raising the height of the home to create a higher ceiling in the basement. Existing detached garage to remain.'
    data = @sizer.parse_line(s, 4)
    assert_equal(0, data[:sqft_list].length)
    #assert_equal(325, data[:sqft_list][0])
    assert_equal(0, data[:sqft_total])
    assert_equal(0, data[:units])
  end

  def test_parse_row5
    s = 'Land Use Application to allow a 3-story building containing 6,220 sq. ft. of retail at ground level and 45,895 sq. ft.  of office space above.  Parking for 83 vehicles to be provided below grade. Project includes 12,050 cu. yds. of grading. Existing structure to be removed.'
    data = @sizer.parse_line(s, 5)
    assert_equal(2, data[:sqft_list].length)
    assert_equal(6220, data[:sqft_list][0])
    assert_equal(45895, data[:sqft_list][1])
    assert_equal(52115, data[:sqft_total])
    assert_equal(0, data[:units])
    assert_equal(false, data[:housing_alert])
  end

  def test_parse_row6
    s = 'Land Use Application to allow a six story, 78 - unit residential building with 3,600 sq. ft. of retail/restaurant and 2 live-work units at ground floor (totaling 5,600 sq. ft.).  Review includes 11,190 sq. ft. demolition of existing structures. Parking for 52 vehicles will be located below grade.'
    data = @sizer.parse_line(s, 6)
    assert_equal(2, data[:sqft_list].length)
    assert_equal(3600, data[:sqft_list][0])
    assert_equal(5600, data[:sqft_list][1])
    assert_equal(9200, data[:sqft_total])
    assert_equal(80, data[:units])
    assert_equal(false, data[:housing_alert])
  end

  def test_parse_row7
    s = 'Shoreline Substantial Development Application to allow a 1,199 sq. ft. floating home in an environmentally critical area. Existing floating home to be removed. Surface parking for one vehicle will be provided on the site. (KCA#379)'
    data = @sizer.parse_line(s, 7)
    assert_equal(1, data[:sqft_list].length)
    assert_equal(1199, data[:sqft_list][0])
    assert_equal(1199, data[:sqft_total])
    assert_equal(0, data[:units])
    assert_equal(true, data[:housing_alert])
  end

  
  def test_parse_row8
    s = 'Land Use Application to allow a 13-story structure containing 137 residential apartment units. Parking for 70 vehicles to be provided below grade.'
    data = @sizer.parse_line(s, 8)
    assert_equal(0, data[:sqft_list].length)
    assert_equal(0, data[:sqft_total])
    assert_equal(137, data[:units])
    assert_equal(false, data[:housing_alert])
  end

  def test_parse_row9
    s = 'Land use permit to allow for a 5-unit 3-story apartment building. Surface parking for 7 vehicles to be provided.'
    data = @sizer.parse_line(s, 9)
    assert_equal(0, data[:sqft_list].length)
    assert_equal(0, data[:sqft_total])
    assert_equal(5, data[:units])
    assert_equal(false, data[:housing_alert])
  end

  def test_parse_row10
    s = 'Council land use action for a contract rezone of 3,000 sq.ft.from SF7200 to L-3 and establish use for 6 townhouses with parking within the structures. Existing single family residence to be removed.'
    data = @sizer.parse_line(s, 10)
    assert_equal(1, data[:sqft_list].length)
    assert_equal(3000, data[:sqft_list][0])
    assert_equal(3000, data[:sqft_total])
    assert_equal(0, data[:units])
    assert_equal(true, data[:housing_alert])
  end

  def test_parse_row14
    s = 'Shoreline Substantial Development Permit to allow one 4-story townhouse structure and six 3-story townhouse structures for a total of 21 units in an environmentally critical area. Parking for 28 vehicles to be provided within the structures. Project includes 8,150 cu. yds. of grading. Existing structures to be removed.'
    data = @sizer.parse_line(s, 14)
    assert_equal(0, data[:sqft_list].length)
    assert_equal(0, data[:sqft_total])
    assert_equal(21, data[:units])
    assert_equal(true, data[:housing_alert])
  end

  def test_parse_row17
    s = 'Shoreline Substantial Development Application to allow 129 sq. ft. of additions and alterations to an existing floating home in an environmentally critical area.'
    data = @sizer.parse_line(s, 17)
    assert_equal(1, data[:sqft_list].length)
    assert_equal(129, data[:sqft_list][0])
    assert_equal(129, data[:sqft_total])
    assert_equal(0, data[:units])
    assert_equal(true, data[:housing_alert])
  end

  def test_parse_row41
    s = 'The proposal is to develop two, 32 story residential towers over an 8 story base structure. Project includes 640 residential units and 34,200 sq ft of  retail space. Parking for 1,063 vehicles to be provided in an above and below grade garage. Project also includes 76,000 cu.yds. of grading. Existing structure to be demolished. Addendum to existing Environmental Impact Statements to be provided (2300 5th Ave development & downtown height and density changes).'
    data = @sizer.parse_line(s, 41)
    assert_equal(1, data[:sqft_list].length)
    assert_equal(34200, data[:sqft_list][0])
    assert_equal(34200, data[:sqft_total])
    assert_equal(640, data[:units])
    assert_equal(false, data[:housing_alert])
  end

end

