class PunchClockTest < MiniTest::Test

  def setup
    Timecop.freeze(Time.new(2015, 01, 28))
  end

  def test_truth
    punch '18-19'
    assert_equal true, true
  end

  def teardown
    clear_hours_folder
  end
end
