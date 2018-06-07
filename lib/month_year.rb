# frozen_string_literal: true

class MonthYear
  attr_reader :month, :year, :date

  def initialize(args)
    @month = args.fetch(:month).to_i
    @year = args.fetch(:year).to_i

    @year += 2000 if @year < 99

    @date = Date.new(@year, @month)
  end

  def next
    next_month = date.next_month
    MonthYear.new(:year => next_month.year, :month => next_month.month)
  end

  def prev
    prev_month = date.prev_month
    MonthYear.new(:year => prev_month.year, :month => prev_month.month)
  end

  # @param m [Integer]
  def month_eq?(m)
    month == m
  end

  # @param y [Integer]
  def year_eq?(y)
    year == y
  end

  def number_of_days
    @number_of_days ||= Date.new(*self, -1).day
  end

  # Enables some fancy stuff.
  #
  # @example Extract year and month with parallel assignment
  #   year, month = month_year
  #
  # @example Create a date
  #   Date.new(*month_year)
  def to_ary
    [year, month]
  end
  alias_method :to_a, :to_ary
end
