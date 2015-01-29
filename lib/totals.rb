module Totals
  def total
    children.inject(0) { |sum, c| sum += c.total }
  end

  def total_str
    Totals.format total
  end

  module_function

  def pad(number)
    number.to_i.to_s.rjust 2, '0'
  end

  def format(seconds)
    seconds = seconds.to_i
    hours   = seconds / 3600
    rest    = seconds - (hours * 3600)
    minutes = rest / 60
    "#{pad hours}:#{pad minutes}"
  end
end
