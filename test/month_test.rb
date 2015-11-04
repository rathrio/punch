require_relative 'config'

class MonthTest < MiniTest::Test
  def setup
    @month = BRFParser.new.parse(<<-EOS)
      Januar 2014

      28.11.14   18:00-19:00   Total: 01:00
      30.12.14   08:00-13:00   Total: 05:00

      Total: 21:00
    EOS
  end

  def test_sorting
    day = Day.from "02.01.15"
    day.add Block.from("14-16", day)
    @month.days << day
    @month.days.sort!

    assert_equal day, @month.days.last
  end

  def test_find_day_by_date_accepts_ddmmyy
    found_day = @month.find_day_by_date('30.12.14')

    assert_equal '30.12.14', found_day.to_s
  end
end
