class Block
  include Attributes
  include Comparable
  include Totals

  attr_accessor :start, :finish, :day
  flag :over_midnight

  def self.from(str, day)
    block = Block.new
    block.day = day
    start_str, finish_str = str.split '-'

    if start_str.empty? || finish_str.empty?
      raise ArgumentError, "\"#{str}\" is not valid Block"
    end

    start_ary  = start_str.split(':')
    finish_ary = finish_str.split(':')

    block.start  = Time.new(day.long_year, day.month, day.day, *start_ary)
    block.finish = Time.new(day.long_year, day.month, day.day, *finish_ary)
    if block.finish < block.start
      block.finish = block.finish.next_day
      day.unhealthy!
      block.over_midnight!
    end
    block
  end

  def to_s
    "#{format start}-#{format finish}"
  end

  def empty?
    total.zero?
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

  private

  def format(time)
    time.strftime "%H:%M"
  end
end
