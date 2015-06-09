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
    start_ary = start_str.split ':'

    if finish_str
      # normal block handling
      finish_ary = finish_str.split ':'
    else
      unless start_str =~ /^\d{1,2}(:\d{2})?$/
        raise ArgumentError, "#{str} is not a valid block"
      end

      # Start ongoing block.
      finish_ary = start_ary

      # Complete ongoing block.
      if (ob = day.blocks.find &:ongoing?)
        day.blocks.delete ob
        start_ary = ob.start_s.split ':'
      end
    end

    if start_ary.empty? && finish_ary.empty?
      raise ArgumentError, "#{str} is not a valid block"
    end

    block.start  = Time.new(day.long_year, day.month, day.day, *start_ary)
    block.finish = Time.new(day.long_year, day.month, day.day, *finish_ary)
    if block.finish < block.start
      block.finish = block.finish.next_day
      day.unhealthy!
      block.over_midnight!
    end
    block
  end

  def to_s(options = {})
    str = "#{format start}-"
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
