require 'rounded_time'

class BlockParser
  # What the start or finish part of a block may look like,
  # e.g. "09:00", "09", "9", etc
  HALF_BLOCK_RGX = /^\d{1,2}:?\d{0,2}$/

  def self.parse(block_str, day)
    new(block_str, day).parse
  end

  def initialize(block_str, day)
    @block_str = block_str
    @day = day
  end

  def parse
    prepare_block_str!
    Block.from(@block_str, @day)
  end

  private

  # Convenience preps specific to CLI block parsing. Translates shorthands to
  # block strings Block.from knows how to deal with.
  #
  # This allows users to
  #
  #   * omit the colon in 4-digit blocks, e.g. "1330" instead of "13:30"
  #   * type out "now" instead of the current time
  #   * start and complet ongoing blocks by typing only a half block
  #
  def prepare_block_str!
    @block_str = @block_str.gsub(/(\d{4})/) { "#{$1[0..1]}:#{$1[2..3]}" }.
      gsub(/now/) { RoundedTime.now.strftime('%H:%M') }

    return unless @block_str =~ HALF_BLOCK_RGX

    @block_str = if (ob = @day.blocks.find(&:ongoing?))
      "#{ob.start_s}-#{@block_str}"
    else
      "#{@block_str}-#{@block_str}"
    end
  end
end
