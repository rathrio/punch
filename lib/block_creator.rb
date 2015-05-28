class BlockCreator

  def self.from(str, day)
    start_str, finish_str = str.split '-'

    start_ary  = start_str.split(':')
    start_time = Time.new(day.long_year, day.month, day.day, *start_ary)

    if finish_str.nil?
      if (hb = day.blocks.find &:halfblock?)
        Block.new(
          :start  => hb.start,
          :finish => start_time
        )
      else
        Halfblock.new(:start => start_time)
      end
    else
      if start_str.empty? || finish_str.empty?
        raise ArgumentError, "\"#{str}\" is not valid Block"
      end

      finish_ary = finish_str.split(':')

      block = Block.new(
        :start  => start_time,
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
