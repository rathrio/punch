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

  def self.name(month_nr)
    NAMES[month_nr]
  end

  def self.build(brf_str, month_nr, year)
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
      unless Punch.config.title.empty?
        name.prepend("#{Punch.config.title} - ")
      end
      name
    end
  end

  def add(*new_days)
    new_days.each do |day|
      if existing = days.find { |d| d.date == day.date }
        existing.add *day.blocks
      else
        self.days << day
      end
    end
  end

  def to_s(options = {})
    color = options.fetch :color, false
    days.sort!
    b_count = max_block_count
    "#{name}#{newline * 2}#{
      days.map { |d|
        d.to_s(:color => color, :padding => b_count)
      }.join(newline)
    }#{newline * 2}Total: #{total_str}#{newline}"
  end

  def colored
    to_s :color => true
  end

  def children
    days
  end

  def blocks
    days.flat_map &:blocks
  end

  def max_block_count
    days.map(&:block_count).max
  end

  def short_year
    year - 2000
  end

  def cleanup!
    days.each(&:cleanup!)
    days.reject!(&:empty?)
  end
end
