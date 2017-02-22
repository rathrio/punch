# encoding: UTF-8
# frozen_string_literal: true

module MonthNames
  NAMES = {
    :en => {
      1  => 'january',
      2  => 'february',
      3  => 'march',
      4  => 'april',
      5  => 'may',
      6  => 'june',
      7  => 'juli',
      8  => 'august',
      9  => 'september',
      10 => 'october',
      11 => 'november',
      12 => 'december'
    },
    :de => {
      1  => 'januar',
      2  => 'februar',
      3  => 'märz',
      4  => 'april',
      5  => 'mai',
      6  => 'juni',
      7  => 'juli',
      8  => 'august',
      9  => 'september',
      10 => 'oktober',
      11 => 'november',
      12 => 'dezember'
    }
  }.freeze

  def self.name(month_nr, lang = Punch.config.language)
    NAMES.fetch(lang.to_sym).fetch(month_nr)
  end
end
