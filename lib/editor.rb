require 'date'

class Editor
  attr_accessor :clock, :month, :days_picked

  def initialize(clock)
    @clock = clock
    @month = clock.month
  end

  def run
    fill_month
    loop do
      print_month
      input = prompt
      exit if %w(q quit exit).include? input
      break if input == 'x'
      clock.edit_brf if input == 'e'
      if days_picked?
        begin
          days_picked.each do |d|
            day = month.days[d - 1]
            blocks = input.strip.split(/\s+/).map { |block_str|
              Block.new block_str, day }
            day.add *blocks
          end
          reset!
        rescue
          next
        end
      else
        @days_picked = input.split(/,|\s+/).map!(&:to_i) unless input.empty?
      end
    end
  ensure
    purge_empty_days
    system 'clear'
  end

  private

  def config
    clock.config
  end

  def fill_month
    current_month_nr = month.number
    current_year     = month.short_year

    if (prev_month_nr = current_month_nr - 1).zero?
      prev_month_nr = 12
      prev_year = current_year - 1
    else
      prev_year = current_year
    end

    current_month_days =
      month.days.select { |d| d.month == current_month_nr }.map &:day

    prev_month_days =
      month.days.select { |d| d.month == prev_month_nr }.map &:day

    ((1..20).to_a - current_month_days).each do |d|
      day = Day.new
      day.day = d
      day.month = current_month_nr
      day.year = current_year
      month.days << day
    end

    (((config.hand_in_date + 1)..days_in_month(prev_year, prev_month_nr)).
      to_a - prev_month_days).each do |d|

      day = Day.new
      day.day = d
      day.month = prev_month_nr
      day.year = prev_year
      month.days << day
    end

    month.days.sort!
  end

  def purge_empty_days
    month.days.reject! &:empty?
  end

  def days_in_month(year, month_nr)
    Date.new(year, month_nr, -1).day
  end

  def title
    "Interactive Punch Beta - Edit #{month.name}\n"
  end

  def prompt
    p = days_picked? ? "Add blocks:" : ">>"
    print "\n#{p} ".pink
    gets.chomp
  end

  def days_picked
    @days_picked ||= []
  end

  def days_picked?
    days_picked.any?
  end

  def reset!
    @days_picked = nil
    @max_block_count = nil
  end

  def print_month
    system 'clear'
    buffer = ''
    buffer << title.pink

    month.days.each_with_index do |d, i|
      index = i + 1
      index_str = "{#{index}}".rjust(4)
      index_str = index_str.pink unless days_picked?
      day_str   = d.to_s(:padding => max_block_count)
      str = index_str + "  #{day_str}"
      if days_picked.include?(index)
        buffer << "\n#{str.pink}"
      else
        buffer << "\n#{str}"
      end
    end

    buffer << "\n"

    buffer << "\nTotal: #{month.total_str}\n"

    buffer << legend('x', 'Save and quit')
    buffer << legend('q', 'Quit without saving')
    buffer << legend('e', 'Open BRF file and quit')

    puts buffer
  end

  def legend(cmd, desc)
    "\n {#{cmd}}".pink + "  #{desc}"
  end

  def max_block_count
    @max_block_count ||= month.max_block_count
  end
end
