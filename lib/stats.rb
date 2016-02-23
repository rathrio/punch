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
  attr_accessor :month

  def initialize(month)
    @month = month
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
    "CHF #{money_made month.total}"
  end

  # Number of blocks where #start and #finish are on different days.
  def late_nights
    blocks.count(&:over_midnight?)
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
      i += 1 while (d = d.next_day(month))
      max = i if i > max
    end
    max
  end

  def progress
    diff = Totals.format(remaining)
    "#{percentage} % | #{Totals.format reached}/#{config.monthly_goal} | "\
      "Diff: #{diff}"
  end

  def workdays_left
    @worddays_left = workdays.count { |d| d > now }
  end

  def average_hours_per_workday_remaining
    if workdays_left.zero?
      Totals.format remaining
    else
      Totals.format(remaining / workdays_left)
    end
  end

  def to_s
    <<-EOS
#{label "Progress"}#{progress}
#{label "Workdays left"}#{workdays_left}
#{label "Hours per workday remaining"}#{average_hours_per_workday_remaining}
#{label "Money made"}#{total_money_made}
#{label "Avg hours per day"}#{average_hours_per_day}
#{label "Avg hours per block"}#{average_hours_per_block}
#{label "Longest day"}#{longest_day}
#{label "Longest block"}#{longest_block}
#{label "Most blocks in day"}#{most_blocks}
#{label "Late nights"}#{late_nights}
#{label "Early mornings"}#{early_mornings}
#{label "Consecutive days"}#{consecutive_days}
#{label "Total days"}#{total_days}
#{label "Total blocks"}#{total_blocks}
    EOS
  end

  private

  def percentage
    (100.0 / monthly_goal * reached).round 2
  end

  def workdays
    @workdays ||= month.workdays
  end

  def monthly_goal
    @monthly_goal ||= config.monthly_goal * 3600
  end

  def reached
    @reached ||= month.total
  end

  def remaining
    @remaining ||= monthly_goal - reached
  end

  def hourly_pay
    @hourly_pay ||= config.hourly_pay
  end

  def config
    Punch.config
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
    "#{str}:".ljust(29).highlighted
  end

  def eight_am(day)
    Time.new(day.year, day.month, day.day, 8)
  end

  def now
    @now ||= Time.now
  end
end
