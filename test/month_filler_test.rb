require_relative 'config'

class MonthFillerTest < PunchTest
  def test_fills_up_month_with_missing_days
    punch '8-9'
    assert_equal 1, current_month.days.count
    MonthFiller.new(current_month).fill!
    assert_equal 31, current_month.days.count
  end
end
