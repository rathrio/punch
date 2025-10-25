require_relative 'config'

class DayTest < Minitest::Test
  def test_from_parses_ddmmyy
    day = Day.from '27.11.14'
    assert_equal 27, day.day
    assert_equal 11, day.month
    assert_equal 2014, day.year
    assert_equal 14, day.short_year
  end

  def test_total
    day = Day.from '08.04.91'
    day.add Block.from("08:00-12:00", day)
    day.add Block.from("13:00-18:00", day)
    assert_equal 32_400, day.total
    assert_equal '09:00', day.total_str
  end

  def test_total_over_midnight
    day = Day.from '24.09.90'
    day.add Block.from('23-02', day)
    day.add Block.from('14-16', day)
    assert_equal '05:00', day.total_str
  end

  def test_total_with_minutes
    day = Day.from '08.04.91'
    day.add Block.from("12:30-19:15", day)
    assert_equal '06:45', day.total_str
  end

  def test_block_ordering
    day = Day.from '26.03.89'
    day.add Block.from("13:30-17:00", day)
    day.add Block.from("06:00-11:45", day)
    assert_equal "26.03.89   06:00-11:45   13:30-17:00   Total: 09:15", day.to_s
  end

  def test_at
    now = Time.now
    today = Day.new
    today.set now
    assert today.at?(now), 'today was not today'
  end

  def test_today?
    Timecop.freeze(Time.new(2014, 12, 20)) do
      now = Time.now
      today = Day.new
      today.set now
      assert today.today?, 'today was not today'
    end
  end

  def test_add_deletes_smaller_blocks
    day = Day.from '26.03.89'
    day.add Block.from("13:15-17:00", day)
    assert_equal '26.03.89   13:15-17:00   Total: 03:45', day.to_s
    day.add Block.from("13:00-18:00", day)
    assert_equal '26.03.89   13:00-18:00   Total: 05:00', day.to_s
  end

  def test_add_ignores_new_smaller_blocks
    day = Day.from '12.04.95'
    day.add Block.from("13:00-17:00", day)
    day.add Block.from("14:00-16:00", day)
    assert_equal '12.04.95   13:00-17:00   Total: 04:00', day.to_s
  end

  def test_prepend_merge
    day = Day.from '12.04.95'
    day.add Block.from("13:15-17:00", day)
    day.add Block.from("13:00-17:00", day)
    assert_equal '12.04.95   13:00-17:00   Total: 04:00', day.to_s
  end

  def test_prepend_merge2
    day = Day.from '05.04.15'
    day.add Block.from("17:50-19:00", day)
    day.add Block.from("18:30-19:00", day)
    assert_equal '05.04.15   17:50-19:00   Total: 01:10', day.to_s
  end

  def test_append_merge
    day = Day.from '12.04.95'
    day.add Block.from("13:00-17:00", day)
    day.add Block.from("16:00-18:00", day)
    assert_equal '12.04.95   13:00-18:00   Total: 05:00', day.to_s
  end

  def test_connect_merge
    day = Day.from '03.05.15'
    day.add Block.from("08:00-12:00", day)
    day.add Block.from("16:00-18:00", day)
    day.add Block.from("10:00-17:00", day)
    assert_equal '03.05.15   08:00-18:00   Total: 10:00', day.to_s
  end

  def test_connect_merge2
    day = Day.from '03.05.15'
    day.add Block.from("08:00-12:00", day),
      Block.from("16:00-18:00", day),
      Block.from("13:00-14:00", day),
      Block.from("22:00-23:00", day),
      Block.from("10:00-17:00", day)
    assert_equal '03.05.15   08:00-18:00   22:00-23:00   Total: 11:00',
      day.to_s
  end

  def test_connect_merge3
    day = Day.from '03.05.15'
    day.add Block.from("08:00-12:00", day),
      Block.from("16:00-18:00", day),
      Block.from("12:00-16:00", day)
    assert_equal '03.05.15   08:00-18:00   Total: 10:00', day.to_s
  end

  def test_remove_at_end
    day = Day.from '03.05.15'
    day.add Block.from("08:00-12:00", day)
    day.remove Block.from("11:00-13:00", day)
    assert_equal '03.05.15   08:00-11:00   Total: 03:00', day.to_s
  end

  def test_time_on_next_day_knows_about_daylight_savings
    day = Day.from '25.10.15'
    assert_equal day.time_on_next_day.day, 26
  end

  def test_comment_writer_strips_and_sets_comment
    day = Day.new
    day.comment = '  chrank wi di, sau  '
    assert_equal 'chrank wi di, sau', day.comment
  end

  def test_comment_writer_replaces_newlines_with_spaces
    day = Day.new
    day.comment = "doo\nbario\nsanchez"
    assert_equal 'doo bario sanchez', day.comment
  end

  def test_workday
    config :workdays => [] do
      monday = Day.from '06.05.19'
      assert monday.workday?

      satuday = Day.from '11.05.19'
      refute satuday.workday?

      sunday = Day.from '12.05.19'
      refute sunday.workday?
    end
  end

  def test_ignore
    day = Day.new
    day.comment = "ignore me man"

    config :ignore_tags => ['foo', 'bar']  do
      refute day.ignore?
    end

    config :ignore_tags => ['ignore']  do
      assert day.ignore?
    end

    config :ignore_tags => []  do
      refute day.ignore?
    end

    config :ignore_tags => ['nore']  do
      refute day.ignore?
    end
  end
end
