# Aggregates super useless stats given an instance of Month.
#
#   Stats.new(month).to_s
#
# might return something like this:
#
#   Total hours:           35:30
#   Money made:            0
#   Total days:            7
#   Total blocks:          12
#   Avg hours per day:     05:04
#   Avg hours per block:   02:57
#   Longest day:           11:00
#   Longest block:         09:00
#   Most blocks in day:    3
#   Late nights:           0
#   Early mornings:        0
#   Consecutive days:      3
#
class Stats
  attr_accessor :month, :hourly_pay

  def initialize(month, hourly_pay = 0)
    @month = month
    @hourly_pay = hourly_pay
  end

  def longest_day
    Totals.format days.map(&:total).max
  end

  def longest_block
    Totals.format blocks.map(&:total).max
  end

  def most_blocks
    days.map(&:block_count).max || 0
  end

  def total_money_made
    "#{money_made month.total} CHF"
  end

  # Number of blocks where #start and #finish are on different days.
  def late_nights
    blocks.count &:over_midnight?
  end

  # Number of blocks where the #start is before 8 am and #finish is after it.
  def early_mornings
    blocks.count do |b|
      eight = eight_am b.day
      b.start <= eight && b.finish > eight
    end
  end

  def total_days
    days.count
  end

  def total_blocks
    blocks.count
  end

  def average_hours_per_day
    return 0 if days.empty?
    Totals.format(month.total / total_days)
  end

  def average_hours_per_block
    return 0 if blocks.empty?
    Totals.format(month.total / total_blocks)
  end

  # Work days streak.
  def consecutive_days
    max = 0
    days[0..days.size - 2].each do |d|
      i = 1
      i += 1 while d = next_day(d)
      max = i if i > max
    end
    max
  end

  def monthly_goal
    goal      = config.monthly_goal * 3600
    actual    = month.total
    remaining = Totals.format(goal - actual)
    "#{Totals.format actual}/#{config.monthly_goal} Diff: #{remaining}"
  end

  def to_s
    <<-EOS
#{label "Total hours"}#{month.total_str}
#{label "Money made"}#{total_money_made}
#{label "Monthly goal"}#{monthly_goal}
#{label "Total days"}#{total_days}
#{label "Total blocks"}#{total_blocks}
#{label "Avg hours per day"}#{average_hours_per_day}
#{label "Avg hours per block"}#{average_hours_per_block}
#{label "Longest day"}#{longest_day}
#{label "Longest block"}#{longest_block}
#{label "Most blocks in day"}#{most_blocks}
#{label "Late nights"}#{late_nights}
#{label "Early mornings"}#{early_mornings}
#{label "Consecutive days"}#{consecutive_days}
    EOS
  end

  private

  def config
    Punch.instance
  end

  def next_day(day)
    days.find { |d| d.at? day.time_on_next_day }
  end

  def days
    @days ||= month.days
  end

  def blocks
    @blocks ||= month.blocks
  end

  def money_made(seconds)
    (hourly_pay / 3600.0 * seconds).round 2
  end

  def label(str)
    "#{str}:".ljust(23).blue
  end

  def eight_am(day)
    Time.new(day.long_year, day.month, day.day, 8)
  end
end
