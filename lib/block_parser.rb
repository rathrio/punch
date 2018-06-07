# frozen_string_literal: true

require 'rounded_time'

# Can translate various string representations of a block (e.g. 12:40-18) into
# an instance of Block.
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

  # @return [Block]
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
  #   * type out three digits for am times, e.g. "930" instead of "09:30"
  #   * type out "now" instead of the current time
  #   * start and complete ongoing blocks by typing only a half block
  #
  def prepare_block_str!
    @block_str = @block_str.
      gsub(/(\d{4})/) { "#{$1[0..1]}:#{$1[2..3]}" }.    # 4 digits
      gsub(/(\d{3})/) { "0#{$1[0]}:#{$1[1..2]}" }.      # 3 digits
      gsub(/now/) { RoundedTime.now.strftime('%H:%M') } # now

    return unless @block_str =~ HALF_BLOCK_RGX

    # Complete or start an ongoing block.
    @block_str = if (ob = @day.blocks.find(&:ongoing?))
      "#{ob.start_s}-#{@block_str}"
    else
      "#{@block_str}-#{@block_str}"
    end
  end
end
