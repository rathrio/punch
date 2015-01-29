class BRFParser

  TOTAL       = /Total:.+$/
  ParserError = Class.new(StandardError)

  def parse(str)
    lines = str.split("\n").map(&:strip).reject &:empty?
    month = Month.new lines.shift
    lines.pop if lines.last =~ TOTAL
    month.days = lines.map do |l|
      l.sub! TOTAL, ''
      day_ary    = l.split
      day        = Day.new(day_ary.shift)
      day.blocks = day_ary.map { |block_str| Block.new block_str, day }
      day
    end
    month
  rescue StandardError => e
    raise ParserError.new("Couldn't parse string: " + e.message)
  end

end
