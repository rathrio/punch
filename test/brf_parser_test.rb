require_relative 'config'

class BRFParserTest < MiniTest::Test
  def setup
    @month = BRFParser.new.parse(<<-EOS)
      Januar 2014

      28.11.14   18:00-19:00   Total: 01:00
      30.12.14   08:00-13:00   Total: 05:00   SUPPORT

      Total: 06:00
    EOS
  end

  def test_parses_name
    assert_equal 'Januar 2014', @month.name
  end

  def test_parses_days_and_blocks
    day1, day2 = @month.days

    assert_equal "18:00-19:00", day1.blocks.first.to_s
    assert_equal "08:00-13:00", day2.blocks.first.to_s
  end

  def test_parses_tags
    assert_equal [:support], @month.days.last.tags
  end

  def test_doesnt_care_about_totals_format
    @month = BRFParser.new.parse(<<-EOS)
      Januar 2014

      28.11.14   18:00-19:00   Total:  1.0
      30.12.14   08:00-13:00   Total:  5.0   SUPPORT

      Total:  6.0
    EOS

    day1, day2 = @month.days
    assert_equal "18:00-19:00", day1.blocks.first.to_s
    assert_equal "08:00-13:00", day2.blocks.first.to_s
    assert_equal 21_600, @month.total
  end

  def test_parse_tags_with_spaces_and_periods
    @month = BRFParser.new.parse(<<-EOS)
      Januar 2014

      30.12.14   08:00-13:00   Total:  5.0   SUPPORT FOO, BAR.CHABIS

      Total:  6.0
    EOS

    day = @month.days.first
    assert_equal [:"support foo", :"bar.chabis"], day.tags
  end
end
