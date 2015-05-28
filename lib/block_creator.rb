class BlockCreator

  def self.from(str, day)
    start_str, finish_str = str.split '-'

    if finish_str.nil?
      # Half block
    else
      # Full block
      if start_str.empty? || finish_str.empty?
        raise ArgumentError, "\"#{str}\" is not valid Block"
      end

      start_ary  = start_str.split(':')
      finish_ary = finish_str.split(':')

      block = Block.new(
        :start  => Time.new(day.long_year, day.month, day.day, *start_ary),
        :finish => Time.new(day.long_year, day.month, day.day, *finish_ary)
      )

      if block.finish < block.start
        block.finish = block.finish.next_day
        day.unhealthy!
        block.over_midnight!
      end

      block
    end
  end

end
