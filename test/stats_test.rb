require_relative 'config'

class StatsTest < PunchTest
  def test_progress
    config :daily_goal => 8, :goal_type => :daily, :ignore_tags => ['ignore'] do
      assert_equal '00:00', Totals.format(stats.reached)
      assert_equal '184:00', Totals.format(stats.goal)

      punch '8-13'
      assert_equal '05:00', Totals.format(stats.reached)
      assert_equal '184:00', Totals.format(stats.goal)

      # Adding hours to a day that we want to ignore...
      punch '8-13 -d 21 -t ignore'
      # ... doesn't change the reached hours...
      assert_equal '05:00', Totals.format(stats.reached)
      # ... and reduces the goal, because this day is now no longer a workday.
      assert_equal '176:00', Totals.format(stats.goal)

      # But the month itself will answer the actual total
      assert_equal '10:00', Totals.format(current_month.total)
    end
  end

  def test_average_hours
    assert_equal '00:00', stats.average_hours_per_day
    assert_equal '00:00', stats.average_hours_per_block

    punch '-d 1 8-10'
    assert_equal '02:00', stats.average_hours_per_day
    assert_equal '02:00', stats.average_hours_per_block

    punch '-d 2 8-9 12-13'
    assert_equal '02:00', stats.average_hours_per_day
    assert_equal '01:20', stats.average_hours_per_block

    punch '-d 3 8-9'
    assert_equal '01:40', stats.average_hours_per_day
    assert_equal '01:15', stats.average_hours_per_block

    config :totals_format => :decimal do
      assert_equal '1.7', stats.average_hours_per_day.strip
      assert_equal '1.3', stats.average_hours_per_block.strip
    end
  end

  def test_consecutive_days
    assert_equal 0, stats.consecutive_days

    punch '-d 1 8-10'
    assert_equal 1, stats.consecutive_days

    punch '-d 3 8-10'
    assert_equal 1, stats.consecutive_days

    punch '-d 2 -t Hi'
    assert_equal 3, stats.consecutive_days
  end

  def test_longest_day_and_block_stats
    assert_equal '00:00', stats.longest_day
    assert_equal '00:00', stats.longest_block
    assert_equal 0, stats.most_blocks

    punch '8-13'
    assert_equal '05:00', stats.longest_day
    assert_equal '05:00', stats.longest_block
    assert_equal 1, stats.most_blocks
    assert_equal 1, stats.total_days
    assert_equal 1, stats.total_blocks

    punch '-d 27 8-14 16-18'
    assert_equal '08:00', stats.longest_day
    assert_equal '06:00', stats.longest_block
    assert_equal 2, stats.most_blocks
    assert_equal 2, stats.total_days
    assert_equal 3, stats.total_blocks
  end

  def test_total_money_made
    assert_equal 'CHF 0.0', stats.total_money_made

    punch '8-15'

    config :hourly_pay => 9000 do
      assert_equal 'CHF 63000.0', stats.total_money_made
    end

    config :hourly_pay => 18.5 do
      assert_equal 'CHF 129.5', stats.total_money_made
    end
  end

  def test_late_nights
    assert_equal 0, stats.late_nights

    punch '-y 23-3'
    assert_equal 1, stats.late_nights

    punch '22-0:15'
    assert_equal 2, stats.late_nights
  end

  def test_early_mornings
    assert_equal 0, stats.early_mornings

    punch '6-12'
    assert_equal 1, stats.early_mornings
  end

  def test_quota
    config :daily_goal => 8, :goal_type => :daily, :hand_in_date => 31 do
      Timecop.freeze(Time.new(2018, 1, 5)) do
        punch '8-17 -d 1'
        punch '8-17 -d 2'
        punch '8-17 -d 3'
        punch '8-17 -d 4'
        punch '8-1030'

        # Not enough worked yet
        assert_equal '01:30', stats.quota

        punch '10-1820'

        # Worked too much
        assert_equal '-06:20', stats.quota
      end
    end
  end

  def test_tag_count
    punch '-d 1 -t Sick'
    punch '-d 2 -t Sick'
    punch '-d 3 -t Vacation'
    punch '-d 4 -t Holiday'

    expected = {
      'Sick' => 2,
      'Vacation' => 1,
      'Holiday' => 1
    }

    assert_equal expected, stats.tag_counts
  end

  private

  def stats
    Stats.new(current_month)
  end
end
