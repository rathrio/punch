require_relative 'config'

class OngoingTest < PunchTest

  # Travel to 28.01.2015. So the current BRF month is February.
  def setup
    Timecop.freeze(Time.new(2015, 01, 28))
  end

  def teardown
    clear_hours_folder
  end

  def test_add_ongoing_block
    punch '12'
    assert_punched(
      '28.01.15   12:00-12:00   Total: 00:00'
    )
  end

  def test_add_ongoing_block_and_block
    punch '12 13:30-15'
    assert_punched(
      '28.01.15   12:00-12:00   13:30-15:00   Total: 01:30'
    )
  end

  def test_complete_ongoing_block
    punch '12'
    punch '14'
    assert_punched(
      '28.01.15   12:00-14:00   Total: 02:00'
    )
  end

  def test_start_ongoing_in_existing_block
    punch '13-15'
    punch '14'
    assert_punched(
      '28.01.15   13:00-15:00   Total: 02:00'
    )
  end

  def test_end_ongoing_block_started_in_existing_block
    punch '13-15'
    punch '14'
    punch '18'
    assert_punched(
      '28.01.15   13:00-15:00   18:00-18:00   Total: 02:00'
    )
  end

  def test_shadow_block_with_complete
    punch '13-13:30 12'
    punch '14'
    assert_punched(
      '28.01.15   12:00-14:00   Total: 02:00'
    )
  end

  def test_overlap_block_with_complete
    punch '12 14-15'
    punch '14:30'
    assert_punched(
      '28.01.15   12:00-15:00   Total: 03:00'
    )
  end

end
