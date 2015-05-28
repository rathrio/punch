require_relative 'config'

class HalfblockTest < PunchTest

  # Travel to 28.01.2015. So the current BRF month is February.
  def setup
    Timecop.freeze(Time.new(2015, 01, 28))
  end

  def teardown
    clear_hours_folder
  end

  def test_add_halfblock
    punch '12'
    assert_punched(
      '28.01.15   12:00-   Total: 00:00'
    )
  end

  def test_add_halfblock_and_block
    punch '12 13:30-15'
    assert_punched(
      '28.01.15   12:00-   13:30-15:00   Total: 01:30'
    )
  end

  def test_complete_halfblock
    punch '12'
    punch '14'
    assert_punched(
      '28.01.15   12:00-14:00   Total: 02:00'
    )
  end

end
