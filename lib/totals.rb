module Totals
  module Formatter
    attr_reader :seconds

    def initialize(seconds)
      @seconds = seconds.to_i
    end
  end

  class DigitalFormatter
    include Formatter

    def format
      hours   = seconds / 3_600
      rest    = seconds - (hours * 3_600)
      minutes = rest / 60

      "#{hours.left_pad}:#{minutes.left_pad}"
    end
  end

  class DecimalFormatter
    include Formatter

    def format
      (seconds / 3_600.0).round(1).left_pad(:with => ' ', :length => 4)
    end
  end

  FORMATTERS = {
    :digital => DigitalFormatter,
    :decimal => DecimalFormatter
  }.freeze

  def total
    children.inject(0) { |sum, c| sum + c.total }
  end

  def total_str
    Totals.format total
  end

  module_function

  def format(seconds, totals_format = Punch.config.totals_format)
    formatter_class = FORMATTERS.fetch(totals_format) do
      raise "Unknown totals format #{totals_format.inspect}"
    end

    formatter_class.new(seconds).format
  end
end
