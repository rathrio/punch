module OptionParsing
  def switch(*names)
    names.each do |n|
      if args.delete(n)
        yield
        return
      end
    end
  end

  def flag(*names)
    names.each do |n|
      if (index = args.index(n))
        argument_index = index + 1
        if (argument = args[argument_index]) && !argument.start_with?('-')
          yield argument
          # Delete flag.
          args.delete_at index
          # Delete flag argument.
          args.delete_at index
          return
        end
      end
    end
  end

  def args=(args)
    @args = args.map do |a|
      if a =~ /^-\w{2,}$/
        a[1..-1].split("").map { |c| c.prepend('-') }
      else
        a
      end
    end.flatten
  end

  def args
    @args
  end
end
