module OptionParsing
  def switch(*names)
    names.each do |n|
      if args.delete(n)
        yield
        break
      end
    end
  end

  def flag(*names)
    names.each do |n|
      next unless (index = args.index(n))
      argument = args[index + 1]
      # Only yield the argument when it is not another option. Note that it
      # can be nil, so flag arguments are optional by default.
      next if argument.to_s.start_with?('-')
      yield argument
      # Delete flag.
      args.delete_at index
      # Delete flag argument.
      args.delete_at index
      break
    end
  end

  def args=(args)
    @args = args.flat_map do |a|
      if a =~ /^-\w{2,}$/
        a[1..-1].split("").map { |c| c.prepend('-') }
      else
        a
      end
    end
  end

  def args
    @args
  end
end
