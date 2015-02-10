class PunchClockTest < MiniTest::Test

  # Travel to 28.01.2015. So the current BRF month is February.
  def setup
    Timecop.freeze(Time.new(2015, 01, 28))
  end

  def test_without_args_prints_month
    punch '8-12 13-17'
    punch
    content = brf_content
    assert_includes content, 'Februar'
    assert_includes content, '2015'
    assert_includes content, 'Total: 08:00'
  end

  def test_today_is_always_listed_in_output
    punch # empty month
    date = '28.01.15'
    refute_includes brf_content, date
    assert_includes output, date
  end

  def test_add_one_block
    punch '18-19'
    assert_includes brf_content, '28.01.15   18:00-19:00   Total: 01:00'
  end

  def test_add_multiple_blocks
    punch '9-12 12:30-17 22-23'
    assert_includes brf_content,
      '28.01.15   09:00-12:00   12:30-17:00   22:00-23:00   Total: 08:30'
  end

  def test_add_block_over_midnight
    punch '23-04'
    assert_includes brf_content, '28.01.15   23:00-04:00   Total: 05:00'
  end

  def test_day_flag
    punch '-d 02.02.15 14-15:45'
    assert_includes brf_content, '02.02.15   14:00-15:45   Total: 01:45'
  end

  def test_yesterday_switch
    punch '-y 11-13'
    assert_includes brf_content, '27.01.15   11:00-13:00   Total: 02:00'
  end

  def teardown
    clear_hours_folder
  end

end