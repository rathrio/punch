require_relative 'config'

class MonthYearFlagTest < PunchTest
  def test_month_flag_sets_month
    punch '--month 3 12-13'

    assert_punched 'Maerz 2015'
    assert_punched '28.01.15   12:00-13:00'
    assert_includes clock.brf_filepath, 'maerz_2015.txt'
  end

  def test_year_flag_sets_year
    punch '--year 2012'

    assert_punched 'Februar 2012'
    assert_includes clock.brf_filepath, 'februar_2012.txt'
  end

  def test_month_and_year_flag_can_be_combined
    punch '--month 8 --year 18'

    assert_punched 'August 2018'
    assert_includes clock.brf_filepath, 'august_2018.txt'
  end
end
