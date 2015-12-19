require 'date'

class MonthFiller

  attr_accessor :month

  def initialize(month)
    @month = month
  end

  # Fills month up with the missing days from one day after the last hand in
  # date to the next hand in date. Used for interactive mode for instance.
  #
  # @return [Month] the complete month.
  def fill!
    current_month_nr = month.number
    current_year     = month.year

    prev_month_nr = month.prev_month_number
    prev_year = month.prev_month_year

    current_month_days =
      month.days.select { |d| d.month == current_month_nr }.map(&:day)

    prev_month_days =
      month.days.select { |d| d.month == prev_month_nr }.map(&:day)

    ((1..Punch.config.hand_in_date).to_a - current_month_days).each do |d|
      day = Day.new
      day.day = d
      day.month = current_month_nr
      day.year = current_year
      month.days << day
    end

    (((Punch.config.hand_in_date + 1)..days_in_month(prev_year, prev_month_nr)).
      to_a - prev_month_days).each do |d|

      day = Day.new
      day.day = d
      day.month = prev_month_nr
      day.year = prev_year
      month.days << day
    end

    month.days.sort!

    month
  end

  private

  def days_in_month(year, month_nr)
    Date.new(year, month_nr, -1).day
  end

end
