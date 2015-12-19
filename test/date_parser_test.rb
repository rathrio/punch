require_relative 'config'

class DateParserTest < PunchTest
  def test_parse_ddmmyy
    day = DateParser.parse("22.01.15", current_month)

    assert_equal 22, day.day
    assert_equal 1, day.month
    assert_equal 2015, day.year
  end

  def test_parse_ddmm_autodetermines_year
    day = DateParser.parse("22.01", current_month)

    assert_equal 22, day.day
    assert_equal 1, day.month
    assert_equal 2015, day.year
  end

  def test_parse_ddmm_considers_hand_in_date
    # Change punch month to January.
    Timecop.freeze(Time.new(2015, 01, 01)) do
      day = DateParser.parse("22.12", current_month)

      assert_equal 22, day.day
      assert_equal 12, day.month
      assert_equal 2014, day.year
    end
  end

  def test_dd_autodetermines_month_and_year
    day = DateParser.parse("22", current_month)

    assert_equal 22, day.day
    assert_equal 1, day.month
    assert_equal 2015, day.year
  end

  def test_dd_considers_hand_in_date
    day = DateParser.parse("30", current_month)

    assert_equal 30, day.day
    assert_equal 1, day.month
    assert_equal 2015, day.year
  end

  def test_dd_considers_hand_in_date_over_year
    # Change punch month to January.
    Timecop.freeze(Time.new(2015, 01, 01)) do
      day = DateParser.parse("30", current_month)

      assert_equal 30, day.day
      assert_equal 12, day.month
      assert_equal 2014, day.year
    end
  end
end
