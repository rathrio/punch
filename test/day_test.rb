class DayTest < PunchTest
  def test_initialize
    day = Day.new '27.11.14'
    assert_equal 27, day.day
    assert_equal 11, day.month
    assert_equal 14, day.year
  end

  def test_total
    day = Day.new '08.04.91'
    day.add Block.new("08:00-12:00", day)
    day.add Block.new("13:00-18:00", day)
    assert_equal 32400, day.total
    assert_equal '09:00', day.total_str
  end

  def test_total_over_midnight
    day = Day.new '24.09.90'
    day.add Block.new('23-02', day)
    day.add Block.new('14-16', day)
    assert_equal '05:00', day.total_str
  end

  def test_total_with_minutes
    day = Day.new '08.04.91'
    day.add Block.new("12:30-19:15", day)
    assert_equal '06:45', day.total_str
  end

  def test_block_ordering
    day = Day.new '26.03.89'
    day.add Block.new("13:30-17:00", day)
    day.add Block.new("06:00-11:45", day)
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

  def test_merge
    day = Day.new '26.03.89'
    day.add Block.new("13:15-17:00", day)
    assert_equal '26.03.89   13:15-17:00   Total: 03:45', day.to_s
    day.add Block.new("13:00-18:00", day)
    assert_equal '26.03.89   13:00-18:00   Total: 05:00', day.to_s
  end

  def test_add_ignore
    day = Day.new '12.04.95'
    day.add Block.new("13:00-17:00", day)
    day.add Block.new("14:00-16:00", day)
    assert_equal '12.04.95   13:00-17:00   Total: 04:00', day.to_s
  end

  def test_start_merge
    day = Day.new '12.04.95'
    day.add Block.new("13:15-17:00", day)
    day.add Block.new("13:00-17:00", day)
    assert_equal '12.04.95   13:00-17:00   Total: 04:00', day.to_s
  end

  def test_end_merge
    day = Day.new '12.04.95'
    day.add Block.new("13:00-17:00", day)
    day.add Block.new("16:00-18:00", day)
    assert_equal '12.04.95   13:00-18:00   Total: 05:00', day.to_s
  end
end
