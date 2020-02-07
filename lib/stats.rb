# frozen_string_literal: true

# Aggregates stats given an instance of Month.
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
    "CHF #{money_made}"
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
    return Totals.format(0) if days.empty?

    Totals.format(monthly_total / total_days)
  end

  def average_hours_per_block
    return Totals.format(0) if blocks.empty?

    Totals.format(monthly_total / total_blocks)
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
    diff = Totals.format(remaining * -1)
    "#{percentage} % | #{Totals.format reached}/#{Totals.format goal} | "\
      "Diff: #{diff}"
  end

  def workdays_left
    @worddays_left = workdays.count { |d| d > now }
  end

  def workdays_left_progress
    "#{workdays_left}/#{workdays.count}"
  end

  def average_hours_per_workday_remaining
    if workdays_left.zero?
      Totals.format remaining
    else
      Totals.format(remaining / workdays_left)
    end
  end

  def to_s
    <<~STATS
      #{label "Progress"}#{progress}
      #{label "Workdays left"}#{workdays_left_progress}
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
      #{label "Quota"}#{quota}
      #{label "Tags"}#{tag_counts_line}
    STATS
  end

  def tag_counts_line
    tag_counts.map { |tag, count| "#{tag}: #{count}" }.join(" | ")
  end

  def percentage
    (100.0 / goal * reached).round 2
  end

  def workdays
    @workdays ||= month.workdays.reject(&:ignore?)
  end

  def monthly_goal
    @monthly_goal ||= config.monthly_goal * 3600
  end

  def monthly_total
    @monthly_total ||= days.inject(0) { |sum, w| sum + w.total }
  end

  def goal
    @goal ||= if config.goal_type == :monthly
                config.monthly_goal
              else
                ((config.daily_goal * workdays.count).round(2) * 3600).floor
              end
  end

  def reached
    monthly_total
  end

  def remaining
    @remaining ||= goal - reached
  end

  def hourly_pay
    @hourly_pay ||= config.hourly_pay
  end

  def config
    Punch.config
  end

  # @return [Hash<String, Integer>],
  #   e.g. { "Holiday" => 5, "Sickday" => 1, ... }
  def tag_counts
    @tag_counts = tags.uniq.map { |t| [t, tags.count(t)] }.to_h
  end

  def tags
    @tags ||= all_days.
      reject { |d| d.comment.nil? }.
      flat_map { |d| d.comment.split }
  end

  def all_days
    @all_days ||= month.days.reject(&:empty?)
  end

  def days
    @days ||= all_days.reject(&:ignore?)
  end

  def blocks
    @blocks ||= days.flat_map(&:blocks)
  end

  def money_made
    (hourly_pay / 3600.0 * reached).round 2
  end

  def label(str)
    "#{str}:".ljust(29).highlighted
  end

  def eight_am(day)
    Time.new(day.year, day.month, day.day, 8)
  end

  def quota
    workdays_passed = workdays.count - workdays_left
    target = ((config.daily_goal * workdays_passed).round(2) * 3600).floor

    Totals.format(target - monthly_total)
  end

  def now
    @now ||= Time.now
  end
end
