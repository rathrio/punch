# frozen_string_literal: true

# Parser for Brigitte-Readable-Format files.
#
# == BRF
#
# BRF (Brigitte-Readable-Format) is simple format that is not only easy to
# parse, but more importantly, easy to read for Brigitte, the accountant of the
# company I work for.
#
# A BRF file may look like this:
#
#   Januar 2015
#
#   18.12.14   09:00-12:00   12:30-17:30   Total: 08:00
#   19.12.14   11:00-20:10                 Total: 09:10
#   23.12.14   09:00-13:00   14:00-18:30   Total: 08:30
#   29.12.14   09:00-13:00   13:30-18:20   Total: 08:50
#
#   Total: 34:30
#
# The first non-empty line in the file is the name. For now, the name does not
# have any significant meaning, but when generating a new file, Punch will
# generate a string consisting of the current month name in German followed by
# the current year.
#
#   month_name YYYY
#
# Then follows a listing of each day with its total.
#
#   dd.mm.yy   HH:MM-HH:MM   ...   Total: HH:MM
#   ...
#
# The last non-empty line states the total hours worked in the month.
#
#   Total: HH:MM
#
class BRFParser
  # Regexp used to extract meta info.
  META_RGX = /Total:\s+\S+\s?(.*)/

  # Error raised when things go awry while parsing.
  ParserError = Class.new(StandardError)

  # Parses str and returns an instance of Month to work with.
  #
  # @param str [String] a string in valid BRF format.
  # @return [Month] an instance of Month that holds the data of the str.
  #
  # @raise [BRFParser::ParserError] if str could not be parsed, e.g. if str is
  #   not in a valid BRF format or there's some bug in the code.
  #
  # @example Parsing a month with two days
  #
  #   str = %{
  #     Januar 2015
  #
  #     18.12.14   09:00-12:00   12:30-17:30   Total: 08:00
  #     19.12.14   11:00-20:10                 Total: 09:10
  #
  #     Total: 17:10
  #   }
  #
  #   month = BRFParser.new.parse(str)
  #   month.name         # => Januar 2015
  #   month.total        # => 61800
  #   month.days.count   # => 2
  #   month.blocks.count # => 3
  #
  def parse(str)
    # Split lines and get rid of whitespace.
    lines = str.split("\n").map(&:strip).reject(&:empty?)

    # First line is the name.
    month = Month.new lines.shift

    # Get rid of total at the end, because it gets recalculated anyways.
    lines.pop if lines.last =~ /Total:/

    # Create days.
    month.days = lines.map do |l|
      # Get rid of total and comments.
      l = l.sub META_RGX, ''
      comment = $1

      # Parse date.
      day_ary = l.split
      day = Day.from(day_ary.shift)

      day.comment = comment unless comment.nil? || comment.empty?
      day.blocks = day_ary.map { |block_str| Block.from block_str, day }
      day
    end

    month
  rescue StandardError => e
    raise ParserError, "Couldn't parse string: #{e.message}"
  end
end
