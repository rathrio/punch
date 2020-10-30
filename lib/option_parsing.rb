# frozen_string_literal: true

# Provides DSL for parsing command line flags and switches.
module OptionParsing
  class MissingRequiredFlagError < ExposableError
    def initialize(flag)
      @flag = flag
    end

    def message
      %{#{@flag.highlighted} requires an argument}
    end
  end
  # Defines a switch, i.e. an option without an argument.
  #
  # @example Defining a "verbose" switch
  #   switch '-v', '--verbose' do
  #     # ...
  #   end
  def switch(*names)
    names.each do |n|
      if args.delete(n)
        yield
        break
      end
    end
  end

  # Defines a flag, i.e. an option with an optional argument.
  #
  # @example Defining a "day" flag
  #   flag '-d', '--day' do |day|
  #     # do something with day
  #   end
  def flag(*names, required: false)
    names.each do |n|
      next unless (index = args.index(n))
      argument = args[index + 1]

      # Only yield the argument when it is not another option. Note that it
      # can be nil, so flag arguments are optional by default.
      next if argument.to_s.start_with?('-')
      raise MissingRequiredFlagError, n if required && argument.nil?

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
