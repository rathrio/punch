class PunchClockTest < MiniTest::Test
  def setup
    Timecop.freeze(Time.new(2015, 01, 28))
  end
  def teardown
  end
end
