require_relative 'config'

class MonthYearFlagTest < PunchTest
  def test_month_flag_sets_month
    punch '--month 3 12-13'

    assert_punched 'Maerz 2015'
    assert_punched '28.01.15   12:00-13:00'
    assert_includes clock.brf_filepath, '2015-3.txt'
  end

  def test_month_flag_takes_optional_year
    punch '--month 3.14 13-14'

    assert_punched 'Maerz 2014'
    assert_punched '28.01.15   13:00-14:00'
    assert_includes clock.brf_filepath, '2014-3.txt'
  end

  def test_year_flag_sets_year
    punch '--year 2012'

    assert_punched 'Februar 2012'
    assert_includes clock.brf_filepath, '2012-2.txt'
  end

  def test_month_and_year_flag_can_be_combined
    punch '--month 8 --year 18'

    assert_punched 'August 2018'
    assert_includes clock.brf_filepath, '2018-8.txt'
  end
end
