require 'rounded_time'

class BlockParser
  attr_accessor :block_str, :day

  def self.parse(block_str, day)
    new(block_str, day).parse
  end

  def initialize(block_str, day)
    @block_str = block_str
    @day = day
  end

  def parse
    Block.from(
      block_str.gsub(/(\d{4})/) { "#{$1[0..1]}:#{$1[2..3]}" }.
        gsub(/now/) { RoundedTime.now.strftime('%H:%M') },
      day
    )
  end
end
