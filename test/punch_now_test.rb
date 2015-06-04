require_relative 'config'

class PunchNowTest < PunchTest

  # Travel to 28.01.2015. So the current BRF month is February.
  def setup
    Timecop.freeze(Time.new(2015, 01, 28, 14))
  end

  def teardown
    clear_hours_folder
  end

  def test_start_ongoing_with_now
    punch 'now'
    assert_punched(
      '28.01.15   14:00-14:00   Total: 00:00'
    )
  end

  def test_complete_ongoing_with_now
    punch '12'
    punch 'now'
    assert_punched(
      '28.01.15   12:00-14:00   Total: 02:00'
    )
  end

  def test_start_and_complete_ongoing_with_now
    punch 'now'
    Timecop.freeze(Time.new(2015, 01, 28, 16)) do
      punch 'now'
    end
    assert_punched(
      '28.01.15   14:00-16:00   Total: 02:00'
    )
  end

  def test_start_block_with_now
    punch 'now-16'
    assert_punched(
      '28.01.15   14:00-16:00   Total: 02:00'
    )
  end

  def test_complete_block_with_now
    punch '12-now'
    assert_punched(
      '28.01.15   12:00-14:00   Total: 02:00'
    )
  end

  def test_now_with_day_flag
    punch '-d 27.01.15 12:00-now'
    assert_punched(
      '27.01.15   12:00-14:00   Total: 02:00'
    )
  end

  def test_now_fair_rounder_round_down
    Timecop.freeze(Time.new(2015, 01, 28, 14, 02)) do
      punch 'now'
    end
    assert_punched(
      '28.01.15   14:00-14:00   Total: 00:00'
    )
  end

  def test_now_fair_rounder_round_up
    Timecop.freeze(Time.new(2015, 01, 28, 14, 03)) do
      punch 'now'
    end
    assert_punched(
      '28.01.15   14:05-14:05   Total: 00:00'
    )
  end

  def test_now_fair_rounder_no_rounding
    Timecop.freeze(Time.new(2015, 01, 28, 14, 05)) do
      punch 'now'
    end
    assert_punched(
      '28.01.15   14:05-14:05   Total: 00:00'
    )
  end

  def test_now_fair_rouder_to_full_hour
    Timecop.freeze(Time.new(2015, 01, 28, 14, 58)) do
      punch '10-now'
    end
    assert_punched(
      '28.01.15   10:00-15:00   Total: 05:00'
    )
  end

  def test_now_with_exact_rounding
    config(:punch_now_rounder => :exact) do
      Timecop.freeze(Time.new(2015, 01, 28, 14, 58)) do
        punch '10-now'
      end
      assert_punched(
        '28.01.15   10:00-14:58   Total: 04:58'
      )
    end
  end

end
