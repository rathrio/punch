class MonthTest < MiniTest::Test
  def test_total_align
    month = BRFParser.new.parse(<<-EOS)
      November 2014

      28.11.14   18:00-19:00   Total: 01:00
      30.11.14   08:00-13:00   Total: 05:00

      Total: 21:00
    EOS

    day1, day2 = month.days
    day2.add Block.new('14-16', day2)

    expected =
      "November 2014\n\n" +
      "28.11.14   18:00-19:00                 Total: 01:00\n" +
      "30.11.14   08:00-13:00   14:00-16:00   Total: 05:00\n\n" +
      "Total: 06:00"
  end

  def test_sorting
    month = BRFParser.new.parse(<<-EOS)
      Januar 2014

      28.11.14   18:00-19:00   Total: 01:00
      30.12.14   08:00-13:00   Total: 05:00

      Total: 21:00
    EOS

    day = Day.new "02.01.15"
    day.add Block.new("14-16", day)
    month.days << day
    month.days.sort!

    assert_equal day, month.days.last
  end
end
