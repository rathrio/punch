require_relative 'config'

class TimeTest < Minitest::Test
  def test_short_year
    assert_equal 16, Time.new(2016).short_year
    assert_equal 99, Time.new(1999).short_year
    assert_equal 2, Time.new(3002).short_year
  end

  def test_acts_like_a_block
    t = Time.new
    assert_equal t, t.start
    assert_equal t, t.finish
  end

  def test_prev_day
    t = Time.new(2016, 5, 12)
    prev_day_t = Time.new(2016, 5, 11)

    assert_equal prev_day_t, t.prev_day
  end

  def test_next_day
    t = Time.new(2016, 5, 12)
    next_day_t = Time.new(2016, 5, 13)

    assert_equal next_day_t, t.next_day
  end
end
