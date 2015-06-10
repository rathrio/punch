require 'month_filler'

class Editor
  attr_accessor :clock, :month, :days_picked

  def initialize(clock)
    @clock = clock
    @month = MonthFiller.new(clock.month).fill!
  end

  def run
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
              Block.from block_str, day }
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
  rescue Interrupt, SystemExit
    exit
  ensure
    month.cleanup!
    system 'clear'
  end

  private

  def config
    clock.config
  end

  def title
    "Interactive Punch - Edit #{month.name}\n"
  end

  def prompt
    p = days_picked? ? "Add blocks:" : ">>"
    print "\n#{p} ".highlighted
    STDIN.gets.chomp
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
    buffer << title.highlighted

    month.days.each_with_index do |d, i|
      index = i + 1
      index_str = "{#{index}}".rjust(4)
      index_str = index_str.highlighted unless days_picked?
      day_str   = "#{d.short_name}  #{d.to_s(:padding => max_block_count)}"
      day_str   = day_str.today_color if d.today? && !days_picked?
      str       = index_str + "  #{day_str}"
      if config.group_weeks_in_interactive_mode? && d.monday? && !i.zero?
        str.prepend("\n")
      end
      if days_picked.include?(index)
        buffer << "\n#{str.highlighted}"
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
    "\n {#{cmd}}".highlighted + "  #{desc}"
  end

  def max_block_count
    @max_block_count ||= month.max_block_count
  end
end
