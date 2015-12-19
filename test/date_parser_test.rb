require_relative 'config'

class DateParserTest < PunchTest
  def test_ddmmyy
    day = DateParser.parse("22.01.15", current_month)

    assert_equal 22, day.day
    assert_equal 1, day.month
    assert_equal 2015, day.year
  end

  def test_ddmm
    day = DateParser.parse("22.01", current_month)

    assert_equal 22, day.day
    assert_equal 1, day.month
    assert_equal 2015, day.year
  end

  def test_dd
    day = DateParser.parse("22", current_month)

    assert_equal 22, day.day
    assert_equal 1, day.month
    assert_equal 2015, day.year
  end
end
