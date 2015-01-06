class Editor
  attr_accessor :month, :day_picked

  def initialize(month)
    @month = month
  end

  def run
    loop do
      print_month
      input = prompt
      break if %w(q quit e exit).include? input
      if day_picked?
        begin
          day = month.days[day_picked - 1]
          blocks = input.strip.split(/\s+/).map { |block_str|
            Block.new block_str, day }
          day.add *blocks
          reset!
        rescue
          next
        end
      else
        @day_picked = input.to_i unless input.empty?
      end
    end
  end

  private

  def title
    "Interactive Punch Beta - Edit #{month.name}\n"
  end

  def prompt
    p = day_picked? ? "Add blocks" : "Pick a day"
    print "\n#{p}: ".pink
    gets.chomp
  end

  def day_picked?
    !!day_picked
  end

  def reset!
    @day_picked = nil
    @max_block_count = nil
  end

  def print_month
    system 'clear'
    puts title.pink
    month.days.each_with_index do |d, i|
      index = i + 1
      index_str = "{#{index}}".rjust(4)
      index_str = index_str.pink unless day_picked?
      str = index_str + "  #{d.to_s(:padding => max_block_count)}"
      if index == day_picked
        puts str.pink
      else
        puts str
      end
    end
  end

  def max_block_count
    @max_block_count ||= month.max_block_count
  end
end
