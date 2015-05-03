class Block
  include Totals
  include Comparable
  attr_accessor :start, :finish, :day
  flag :over_midnight

  def initialize(str, day)
    @day = day
    start_str, finish_str = str.split '-'

    if start_str.empty? || finish_str.empty?
      raise ArgumentError, "\"#{str}\" is not valid Block"
    end

    start_ary  = start_str.split(':')
    finish_ary = finish_str.split(':')

    @start  = Time.new(day.long_year, day.month, day.day, *start_ary)
    @finish = Time.new(day.long_year, day.month, day.day, *finish_ary)
    if @finish < @start
      @finish = @finish.next_day
      day.unhealthy!
      over_midnight!
    end
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

  def include?(time)
    (start <= time) && (finish >= time)
  end

  def strict_include?(time)
    (start < time) && (finish > time)
  end

  private

  def format(time)
    time.strftime "%H:%M"
  end
end
