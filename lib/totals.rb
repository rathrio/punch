# frozen_string_literal: true

module Totals
  def total
    children.inject(0) { |sum, c| sum + c.total }
  end

  def total_str
    Totals.format total
  end

  module_function

  def format(seconds, totals_format = Punch.config.totals_format)
    case totals_format
    when :digital
      digital_format(seconds.to_i)
    when :decimal
      decimal_format(seconds.to_i)
    else
      raise "Unknown totals format #{totals_format.inspect}"
    end
  end

  def digital_format(seconds)
    hours   = seconds / 3_600
    rest    = seconds - (hours * 3_600)
    minutes = rest / 60

    "#{hours.left_pad}:#{minutes.left_pad}"
  end

  def decimal_format(seconds)
    (seconds / 3_600.0).round(1).left_pad(:with => ' ', :length => 4)
  end
end
