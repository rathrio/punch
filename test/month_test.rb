require_relative 'config'

class MonthTest < PunchTest
  def test_sorting
    month = BRFParser.new.parse(<<-EOS)
      Januar 2014

      28.11.14   18:00-19:00   Total: 01:00
      30.12.14   08:00-13:00   Total: 05:00

      Total: 21:00
    EOS

    day = Day.from "02.01.15"
    day.add Block.from("14-16", day)
    month.days << day
    month.days.sort!

    assert_equal day, month.days.last
  end
end
