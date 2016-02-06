class MonthYear
  attr_reader :month, :year, :date

  def initialize(args)
    @month = args.fetch(:month)
    @year = args.fetch(:year)
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

  def month_eq?(m)
    month == m
  end

  def year_eq?(y)
    year == y
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
