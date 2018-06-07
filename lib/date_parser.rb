# frozen_string_literal: true

# Can translate various string representations of a date (e.g. 12.04.95) into
# an instance of Day.
class DateParser
  def self.parse(date, month)
    new(date, month).parse
  end

  attr_reader :date, :month

  def initialize(date, month)
    @date = date
    @month = month
  end

  def parse
    case date

    when /^\d{1,2}$/
      d = date.to_i
      if d > hand_in_date
        y, m = month.prev_month_year
      else
        m = month.number
        y = month.year
      end

    when /^\d{1,2}\.\d{1,2}$/
      d, m = date.split('.').map(&:to_i)
      y = if d > hand_in_date
        month.prev_month_year.year
      else
        month.year
      end

    when /^\d{1,2}\.\d{1,2}\.\d{2,4}$/
      d, m, y = date.split('.').map(&:to_i)
      y += 2000 if y < 100

    else
      raise "\"#{date}\" is in an unknown date format"
    end

    Day.new(
      :day => d,
      :month => m,
      :year => y
    )
  end

  private

  def hand_in_date
    Punch.config.hand_in_date
  end
end
