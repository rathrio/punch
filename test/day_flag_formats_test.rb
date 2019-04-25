# frozen_string_literal: true

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

  def test_comma_separated
    punch '-d 2,3,5 14-15'

    assert_punched '02.02.15   14:00-15:00   Total: 01:00'
    assert_punched '03.02.15   14:00-15:00   Total: 01:00'
    refute_punched '04.02.15'
    assert_punched '05.02.15   14:00-15:00   Total: 01:00'
  end

  def test_ranges
    punch '-d 2-5 -t Holiday'

    refute_punched '01.02.15'
    assert_punched '02.02.15   Total: 00:00   Holiday'
    assert_punched '03.02.15   Total: 00:00   Holiday'
    assert_punched '04.02.15   Total: 00:00   Holiday'
    assert_punched '05.02.15   Total: 00:00   Holiday'
    refute_punched '06.02.15'
  end

  def test_commas_and_ranges
    punch '-d 1-3,6,10-12 -t Holiday'

    assert_punched '01.02.15   Total: 00:00   Holiday'
    assert_punched '02.02.15   Total: 00:00   Holiday'
    assert_punched '03.02.15   Total: 00:00   Holiday'
    refute_punched '04.02.15'
    refute_punched '05.02.15'
    assert_punched '06.02.15   Total: 00:00   Holiday'
    refute_punched '07.02.15'
    refute_punched '08.02.15'
    refute_punched '09.02.15'
    assert_punched '10.02.15   Total: 00:00   Holiday'
    assert_punched '11.02.15   Total: 00:00   Holiday'
    assert_punched '12.02.15   Total: 00:00   Holiday'
  end
end
