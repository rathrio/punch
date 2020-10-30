require_relative 'config'

class RemoveTest < PunchTest
  def test_removing_at_start
    brf_write %{
      Februar 2015

      28.01.15   08:00-12:00   Total: 04:00

      Total: 04:00
    }

    punch '--remove 8-11'
    assert_punched '28.01.15   11:00-12:00   Total: 01:00'
  end

  def test_removing_at_finish
    brf_write %{
      Februar 2015

      28.01.15   08:00-12:00   Total: 04:00

      Total: 04:00
    }

    punch '--remove 11:30-12'
    assert_punched '28.01.15   08:00-11:30   Total: 03:30'
  end

  def test_splitting
    brf_write %{
      Februar 2015

      28.01.15   08:00-12:00   Total: 04:00

      Total: 04:00
    }

    punch '--remove 9-10'
    assert_punched '28.01.15   08:00-09:00   10:00-12:00   Total: 03:00'
  end

  def test_shadowing
    brf_write %{
      Februar 2015

      28.01.15   08:00-12:00   13:00-17:00   Total: 08:00

      Total: 08:00
    }

    punch '--remove 7-12:30'
    assert_punched '28.01.15   13:00-17:00   Total: 04:00'
  end

  def test_shadowing2
    brf_write %{
      Februar 2015

      28.01.15   08:00-12:00   13:00-17:00   Total: 08:00

      Total: 08:00
    }

    punch '--remove 8-12'
    assert_punched '28.01.15   13:00-17:00   Total: 04:00'
  end

  def test_remove_at_start_and_finish
    brf_write %{
      Februar 2015

      28.01.15   08:00-12:00   13:00-17:00   Total: 08:00

      Total: 08:00
    }

    punch '--remove 11-14'
    assert_punched '28.01.15   08:00-11:00   14:00-17:00   Total: 06:00'
  end

  def test_remove_cleans_up_after
    brf_write %{
      Februar 2015

      27.01.15   08:00-12:00   13:00-17:00   Total: 08:00

      Total: 08:00
    }

    punch '-d 27.01.15 -r 8-18'
    refute_punched '27.01.15'
  end

  def test_remove_is_flag_with_one_block_argument
    punch '8-17 -r 12-13'
    assert_punched '28.01.15   08:00-12:00   13:00-17:00   Total: 08:00'
  end

  def test_remove_is_flag_with_one_block_argument2
    punch '8-17 -r 12-13 19-20'
    assert_punched '28.01.15   08:00-12:00   13:00-17:00   19:00-20:00   Total: 09:00'
  end

  def test_remove_does_not_take_half_block
    assert_raises(PunchClock::CannotRemoveHalfBlockError) do
      punch '8-17 -r 12'
    end
  end
end
