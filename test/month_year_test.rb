require_relative 'config'

class MonthYearTest < MiniTest::Test
  def test_number_of_days
    month_year = MonthYear.new(:month => 11, :year => 2016)
    assert_equal 30, month_year.number_of_days

    month_year = MonthYear.new(:month => 12, :year => 2014)
    assert_equal 31, month_year.number_of_days

    month_year = MonthYear.new(:month => 2, :year => 2016)
    assert_equal 29, month_year.number_of_days

    month_year = MonthYear.new(:month => 2, :year => 2017)
    assert_equal 28, month_year.number_of_days
  end
end
