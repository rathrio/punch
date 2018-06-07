# frozen_string_literal: true

class Day
  include Attributes
  include Comparable
  include Totals

  attr_accessor :day, :month, :blocks
  attr_reader :short_year, :year, :comment

  flag :highlight, :unhealthy

  # @param [String] date a date of format "DD.MM.YY", e.g., "26.03.15".
  def self.from(date)
    day = Day.new
    day.day, day.month, day.short_year = date.split('.').map(&:to_i)
    day
  end

  def day?(day_nr)
    day == day_nr.to_i
  end

  def month?(month_nr)
    month == month_nr.to_i
  end

  def year?(year_nr)
    year_nr = year_nr.to_i
    short_year == year_nr || year == year_nr
  end

  def short_year=(yy)
    @short_year = yy
    @year = yy + 2000
  end

  def year=(yyyy)
    @year = yyyy
    @short_year = yyyy.to_s[-2..-1].to_i
  end

  def comment=(new_comment)
    @comment = new_comment.to_s.strip.tr("\n", " ")
  end

  # @return [Boolean] whether the stats should ignore this day.
  def ignore?
    Punch.config.ignore_tags.any? { |tag| comment =~ /\b#{tag}\b/i }
  end

  def date
    "#{day.left_pad}.#{month.left_pad}.#{short_year}"
  end

  def monday?
    to_time.monday?
  end

  def workday?
    if Punch.config.workdays.empty?
      return !(to_time.saturday? || to_time.sunday?)
    end

    Punch.config.workdays.any? { |day| to_time.send("#{day}?") }
  end

  def to_time
    @time ||= Time.new year, month, day
  end

  def short_name
    to_time.strftime('%a')
  end

  def time_on_next_day
    to_time.to_date.next_day.to_time
  end

  def next_day(month)
    month.days.find { |d| d.at? time_on_next_day }
  end

  def to_s(options = {})
    blocks.sort!
    blocks_str = +blocks.map { |b| b.to_s(options) }.join('   ')

    # Padding before "Total:"
    max_block_count = options.fetch :padding, 0
    if block_count < max_block_count
      (max_block_count - block_count).times do
        blocks_str << '              '
      end
    end

    str = +"#{date}   #{blocks_str}"
    str << '   ' if blocks.any?
    str << "Total: #{total_str}"
    str << "   #{comment}" if comment

    if options.fetch :prepend_name, false
      str = str.prepend "#{short_name}   "
    end

    if options.fetch :fancy, false
      return str.highlighted if highlight?
      return str.today_color if today?
    end

    str
  end

  def empty?
    blocks.empty? && comment.nil?
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
      self.blocks.reject! do |b|
        b.start >= block.start && b.finish <= block.finish
      end

      # Ignore new block if an existing block covers the new block's span.
      if self.blocks.any? { |b| b.start <= block.start && b.finish >= block.finish }
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
      # Get rid of old blocks with shorter spans than block's. Shadowing.
      self.blocks.reject! { |b| block.include?(b) }

      # Splitting up :(
      if (to_split = self.blocks.find { |b| b.strict_include?(block) })
        new_block = Block.new(
          :start  => block.finish,
          :finish => to_split.finish
        )
        to_split.finish = block.start
        self.blocks << new_block
      end

      # Removing at start.
      if (b = self.blocks.find { |b| b.strict_include? block.finish })
        b.start = block.finish
      end

      # Removing at finish.
      if (b = self.blocks.find { |b| b.strict_include? block.start })
        b.finish = block.start
      end
    end
  end

  def children
    blocks
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
    (day == time.day) && (month == time.month) && (year == time.year)
  end
  alias_method :include?, :at?

  def today?
    at? Time.now
  end

  def set(time)
    self.day   = time.day
    self.month = time.month
    self.year  = time.year
  end

  def remove_ongoing_blocks!
    blocks.reject!(&:ongoing?)
  end
end
