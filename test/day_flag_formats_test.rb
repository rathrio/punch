require_relative 'config'

class DayFlagFormatsTest < PunchTest
  def test_ddmmyy
    punch '-d 02.02.15 8-11'
    assert_punched '02.02.15   08:00-11:00'
  end

  def test_ddmmyyyy
    punch '-d 02.02.2015 8-11'
    assert_punched '02.02.15   08:00-11:00'
  end

  def test_ddmm
    punch '-d 02.02 8-11'
    assert_punched '02.02.15   08:00-11:00'
  end

  def test_dd_is_smart_and_loyal
    punch '-d 23 8-11'
    assert_punched '23.01.15   08:00-11:00'

    punch '-d 2 8-11'
    assert_punched '02.02.15   08:00-11:00'

    punch '-d 20 8-11'
    assert_punched '20.02.15   08:00-11:00'
  end
end
