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

  def test_next_number_and_year_work_as_expected
    month = Month.new('FOO')
    month.number = 11
    month.year = 2015

    assert_equal 12, month.next_month_number
    assert_equal 2015, month.next_month_year

    month = Month.new("BAR")
    month.number = 12
    month.year = 2015

    assert_equal 1, month.next_month_number
    assert_equal 2016, month.next_month_year
  end

  def test_prev_number_and_year_work_as_expected
    month = Month.new('FOO')
    month.number = 11
    month.year = 2015

    assert_equal 10, month.prev_month_number
    assert_equal 2015, month.prev_month_year

    month = Month.new("BAR")
    month.number = 1
    month.year = 2015

    assert_equal 12, month.prev_month_number
    assert_equal 2014, month.prev_month_year
  end
end
