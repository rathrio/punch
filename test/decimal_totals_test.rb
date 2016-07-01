require_relative 'config'

class DecimalTotalsTest < PunchTest
  def test_decimal_option_works
    config :totals_format => :decimal do
      punch '8-10'
      assert_punched 'Total:  2.0'

      punch '12-22:30'
      assert_punched 'Total: 12.5'

      punch '23:00-23:22'
      assert_punched 'Total: 12.9'
    end
  end
end
