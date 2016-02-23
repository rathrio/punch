class Month
  include Totals

  NEWLINE = "\r\n"

  NAMES = {
    1  => 'januar',
    2  => 'februar',
    3  => 'maerz',
    4  => 'april',
    5  => 'mai',
    6  => 'juni',
    7  => 'juli',
    8  => 'august',
    9  => 'september',
    10 => 'oktober',
    11 => 'november',
    12 => 'dezember',
  }

  attr_accessor :name, :days, :number, :year

  alias_method :month, :number

  def self.name(month_nr)
    NAMES[month_nr]
  end

  def self.from(brf_str, month_nr, year)
    month        = BRFParser.new.parse(brf_str)
    month.number = month_nr
    month.year   = year
    month
  end

  def initialize(name)
    @name = name
    @days = []
  end

  def newline
    NEWLINE
  end

  def name
    if year.nil? || number.nil?
      @name
    else
      name = "#{NAMES[number].capitalize} #{year} - #{Punch.config.name}"
      name.prepend("#{Punch.config.title} - ") unless Punch.config.title.empty?
      name
    end
  end

  def add(*new_days)
    new_days.each do |day|
      if (existing = days.find { |d| d.date == day.date })
        existing.add(*day.blocks)
      else
        days << day
      end
    end
  end

  def to_s(options = {})
    days.sort!
    b_count = max_block_count
    day_options = options.merge :padding => b_count
    "#{name}#{newline * 2}#{
      days.map do |d|
        d.to_s(day_options)
      end.join(newline)
    }#{newline * 2}Total: #{total_str}#{newline}"
  end

  def find_or_create_day_by_date(date)
    day_nr, month_nr, year_nr = date.split('.')

    day = days.find do |d|
      (day_nr   ? d.day?(day_nr)     : true) &&
      (month_nr ? d.month?(month_nr) : true) &&
      (year_nr  ? d.year?(year_nr)   : true)
    end

    if day.nil?
      day = DateParser.parse(date, self)
      add day
    else
      day
    end

    day
  end

  def month_year
    @month_year ||= MonthYear.new(:month => number, :year => year)
  end

  def prev_month_year
    month_year.prev
  end

  def next_month_year
    month_year.next
  end

  def to_date
    month_year.date
  end

  def fancy
    to_s :fancy => true
  end

  def full
    full_month.to_s :fancy => true, :prepend_name => true
  end

  def full_month
    @full_month ||= FullMonth.new(self).full_month
  end

  def workdays
    full_month.days.select(&:workday?)
  end

  def children
    days
  end

  def blocks
    days.flat_map(&:blocks)
  end

  def max_block_count
    days.map(&:block_count).max
  end

  def short_year
    year - 2000
  end

  def cleanup!(options = {})
    days.each(&:remove_ongoing_blocks!) if options[:remove_ongoing_blocks]
    days.reject!(&:empty?)
  end
end
