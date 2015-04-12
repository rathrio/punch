class Merger
  attr_reader :cards, :month_nr, :month_name, :year

  def initialize(cards, month_nr, year)
    raise ArgumentError, "cards must not be empty" if cards.empty?
    @cards = cards
    @month_nr = month_nr
    @month_name = Month.name(month_nr)
    @year = year
  end

  def month
    merged_month = Month.new("#{cards.join(", ")} "\
      "- #{month_name.capitalize} #{year}")

    cards.each do |card|
      next unless (card_config = config.cards[card.to_sym])
      hours_folder = card_config.fetch(:hours_folder) { next }
      brf_file_path = "#{hours_folder}/#{month_name}_#{year}.txt"
      begin
        month = Month.build(File.read(brf_file_path), month_nr, year)
      rescue Errno::ENOENT
        next
      end
      new_days = month.days
      merged_month.add *new_days
    end

    merged_month
  end

  private

  def config
    Punch.instance
  end
end
