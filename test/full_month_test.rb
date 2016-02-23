require_relative 'config'

class FullMonthTest < PunchTest
  def test_fills_up_month_with_missing_days
    punch '8-9'
    assert_equal 1, current_month.days.count
    full_month = FullMonth.new(current_month).full_month
    assert_equal 31, full_month.days.count
  end
end
