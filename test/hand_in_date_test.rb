require_relative 'config'

class HandInDateTest < PunchTest
  def test_month_switch_in_middle
    config :hand_in_date => 20 do
      Timecop.travel(Time.new(2016, 11, 11))
      punch '8-10'
      assert_equal 11, current_month.number
      assert_punched 'November'

      Timecop.travel(Time.new(2016, 11, 20))
      punch '8-10'
      assert_equal 11, current_month.number
      assert_punched 'November'


      Timecop.travel(Time.new(2016, 11, 23))
      punch '8-10'
      assert_equal 12, current_month.number
      assert_punched 'Dezember'
    end
  end

  def test_month_switch_at_end
    config :hand_in_date => 31 do
      Timecop.travel(Time.new(2016, 11, 23))
      punch '8-10'
      assert_equal 11, current_month.number
      assert_punched 'November'

      Timecop.travel(Time.new(2016, 11, 30))
      punch '8-10'
      assert_equal 11, current_month.number
      assert_punched 'November'

      Timecop.travel(Time.new(2016, 12, 1))
      punch '8-10'
      assert_equal 12, current_month.number
      assert_punched 'Dezember'

      Timecop.travel(Time.new(2016, 12, 31))
      punch '8-10'
      assert_equal 12, current_month.number
      assert_punched 'Dezember'

      Timecop.travel(Time.new(2017, 1, 1))
      punch '8-10'
      assert_equal 1, current_month.number
      assert_equal 2017, current_month.year
      assert_punched 'Januar'
    end
  end
end
