# frozen_string_literal: true

class Editor
  attr_accessor :month, :days_picked

  def initialize(month)
    @month = month.full_month
  end

  # @return [Month] the edited month.
  def run
    loop do
      print_month
      input = prompt
      exit if %w(q quit exit).include? input
      break if input == 'x'
      if days_picked?
        begin
          days_picked.each do |d|
            day = month.days[d - 1]
            blocks = input.strip.split(/\s+/).map do |block_str|
              BlockParser.parse block_str, day
            end
            day.add(*blocks)
          end
          reset!
        rescue
          next
        end
      else
        @days_picked = input.split(/,|\s+/).map!(&:to_i) unless input.empty?
      end
    end
    month
  rescue Interrupt, SystemExit
    exit
  ensure
    month.cleanup!
    system 'clear'
  end

  private

  def config
    Punch.config
  end

  def title
    "#{month.name}\n"
  end

  def prompt
    p = days_picked? ? "Add blocks:" : ">>"
    print "\n#{p} ".highlighted
    config.in.gets.chomp
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
    buffer = +''
    buffer << title.highlighted

    month.days.each_with_index do |d, i|
      index = i + 1
      index_str = "{#{index}}".rjust(4)
      index_str = index_str.highlighted unless days_picked?
      day_str   = "#{d.short_name}  #{d.to_s(:padding => max_block_count)}"
      day_str   = day_str.today_color if d.today? && !days_picked?
      str       = +(index_str + "  #{day_str}")
      if config.group_weeks_in_interactive_mode? && d.monday? && !i.zero?
        str.prepend("\n")
      end
      buffer << if days_picked.include?(index)
        "\n#{str.highlighted}"
      else
        "\n#{str}"
      end
    end

    buffer << "\n"

    buffer << "\nTotal: #{month.total_str}\n"

    buffer << legend('x', 'Save and quit')
    buffer << legend('q', 'Quit without saving')

    puts buffer
  end

  def legend(cmd, desc)
    "\n {#{cmd}}".highlighted + "  #{desc}"
  end

  def max_block_count
    @max_block_count ||= month.max_block_count
  end
end
