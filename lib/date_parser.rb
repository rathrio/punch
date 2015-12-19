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
      Day.new(
        :day => d,
        :month => m,
        :year => y
      )
    when /^\d{1,2}\.\d{1,2}$/
      d, m = date.split('.').map(&:to_i)
      Day.new(
        :day => d,
        :month => m,
        :year => month.year
      )
    when /^\d{1,2}\.\d{1,2}\.\d{2,4}$/
      Day.from(date)
    else
      raise "\"#{date}\" is in an unknown date format"
    end
  end
end
