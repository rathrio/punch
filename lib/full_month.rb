# Fills month up with the missing days from one day after the last hand in
# date to the next hand in date. Used for interactive mode for instance.
class FullMonth
  attr_accessor :month

  def initialize(month)
    @month = Marshal.load Marshal.dump(month)
  end

  # @return [Month] the complete month.
  def full_month
    current_month_year = month.month_year
    prev_month_year = current_month_year.prev

    current_month_days =
      month.days.select { |d| current_month_year.month_eq? d.month }.map(&:day)

    prev_month_days =
      month.days.select { |d| prev_month_year.month_eq? d.month }.map(&:day)

    ((1..Punch.config.hand_in_date).to_a - current_month_days).each do |d|
      day = Day.new
      day.day = d
      day.year, day.month = current_month_year
      month.days << day
    end

    (((Punch.config.hand_in_date + 1)..prev_month_year.number_of_days).
      to_a - prev_month_days).each do |d|

      day = Day.new
      day.day = d
      day.year, day.month = prev_month_year
      month.days << day
    end

    month.days.sort!

    month
  end
end
