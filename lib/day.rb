class Day
  include Attributes
  include Comparable
  include Totals

  attr_accessor :day, :month, :year, :blocks
  flag :highlight, :unhealthy

  # @ param date [String] a date of format "DD.MM.YY", e.g., "26.03.15".
  def self.from(date)
    day = Day.new
    day.day, day.month, day.year = date.split('.').map &:to_i
    day
  end

  def date
    "#{pad day}.#{pad month}.#{year}"
  end

  def monday?
    to_time.monday?
  end

  def to_time
    Time.new long_year, month, day
  end

  def short_name
    to_time.strftime('%a')
  end

  def time_on_next_day
    to_time.next_day
  end

  def to_s(options = {})
    blocks.sort!
    blocks_str = blocks.join('   ')
    max_block_count = options.fetch :padding, 0
    if block_count < max_block_count
      (max_block_count - block_count).times do
        # Padding before "Total:"
        blocks_str << '              '
      end
    end
    str = "#{date}   #{blocks_str}   "
    str << "Total: #{total_str}" if blocks.any?
    if options.fetch :color, false
      return str.pink if highlight?
      return str.blue if today?
    end
    str
  end

  def empty?
    blocks.empty?
  end

  def blocks
    @blocks ||= []
  end

  def block_count
    blocks.count
  end

  def add(*blocks)
    highlight!
    blocks.each do |block|

      # Get rid of old blocks with shorter spans than block's.
      self.blocks.reject! { |b|
        b.start >= block.start && b.finish <= block.finish }

      # Ignore new block if an existing block covers the new block's span.
      if self.blocks.any? { |b|
        b.start <= block.start && b.finish >= block.finish }
        next
      end

      # Connecting.
      if self.blocks.count > 1
        if (start_overlap = self.blocks.find { |b| b.include?(block.start) })
          if (finish_overlap = self.blocks.reverse.
                find { |b| b.include?(block.finish) })
            start_overlap.finish = finish_overlap.finish
            self.blocks.delete(finish_overlap)
            next
          end
        end
      end

      # Prepending.
      if (overlap = self.blocks.find { |b| b.include?(block.finish) })
        overlap.start = block.start
        next
      end

      # Appending.
      if (overlap = self.blocks.find { |b| b.include?(block.start) })
        overlap.finish = block.finish
        next
      end

      self.blocks << block
    end
  end

  def remove(*blocks)
    highlight!
    blocks.each do |block|
      # Get rid of old blocks with shorter spans than block's.
      self.blocks.reject! { |b|
        b.start >= block.start && b.finish <= block.finish }

      # Splitting up :(
      if (to_split = self.blocks.find { |b| b.strict_include?(block) })
        new_block = Block.new
      end
    end
  end

  def children
    blocks
  end

  def long_year
    year + 2000
  end

  def <=>(other)
    if year == other.year
      if month == other.month
        day <=> other.day
      else
        month <=> other.month
      end
    else
      year <=> other.year
    end
  end

  def at?(time)
    (day == time.day) && (month == time.month) && (year == time.short_year)
  end
  alias_method :include?, :at?

  def today?
    at? Time.now
  end

  def set(time)
    @day   = time.day
    @month = time.month
    @year  = time.short_year
  end

  def cleanup!
    blocks.reject!(&:empty?)
  end
end
