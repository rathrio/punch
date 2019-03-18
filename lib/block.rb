# frozen_string_literal: true

class Block
  include Attributes
  include Comparable
  include Totals

  class BlockFormatError < StandardError
    def initialize(input)
      @input = input
    end

    def message
      %{"#{@input}" is not a valid block}
    end
  end

  attr_accessor :start, :finish, :day
  flag :over_midnight

  def self.from(str, day)
    block = Block.new
    block.day = day

    start_str, finish_str = str.split '-'
    start_ary = start_str.split ':'
    finish_ary = finish_str.split ':'

    raise BlockFormatError, str if start_ary.empty? && finish_ary.empty?

    block.start  = Time.new(day.year, day.month, day.day, *start_ary)
    block.finish = Time.new(day.year, day.month, day.day, *finish_ary)
    if block.finish < block.start
      block.finish = block.finish.next_day
      day.unhealthy!
      block.over_midnight!
    end
    block
  end

  def to_s(options = {})
    str = +"#{format start}-"
    return str << '     ' if options[:fancy] && ongoing?
    str << format(finish)
  end

  def total
    (finish - start).to_i
  end

  def <=>(other)
    start <=> other.start
  end

  # @param t [#start, #finish]
  def include?(t)
    (start <= t.start) && (finish >= t.finish)
  end

  # @param t [#start, #finish]
  def strict_include?(t)
    (start < t.start) && (finish > t.finish)
  end

  def start_s
    format start
  end

  def finish_s
    format finish
  end

  def ongoing?
    start == finish
  end

  private

  def format(time)
    time.strftime "%H:%M"
  end
end
