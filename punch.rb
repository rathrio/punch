#!/usr/bin/env ruby

# The MIT License (MIT)
#
# Copyright (c) 2014 Rathesan Iyadurai
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

class Time
  def short_year
    strftime('%y').to_i
  end
end

class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green
    colorize 32
  end

  def blue
    colorize 34
  end

  def pink
    colorize 35
  end
end

class BRFParser
  TOTAL = /Total:.+$/
  ParserError = Class.new(StandardError)
  def parse(str)
    lines = str.split("\n").map(&:strip).reject &:empty?
    month = Month.new lines.shift
    lines.pop if lines.last =~ TOTAL
    month.days = lines.map do |l|
      l.sub! TOTAL, ''
      day_ary    = l.split
      day        = Day.new(day_ary.shift)
      day.blocks = day_ary.map { |block_str| Block.new block_str, day }
      day
    end
    month
  rescue StandardError => e
    raise ParserError.new("Couldn't parse string: " + e.message)
  end
end

module Totals
  def total
    children.inject(0) { |sum, c| sum += c.total }
  end

  def total_str
    t       = total
    hours   = t / 3600
    rest    = t - (hours * 3600)
    minutes = rest / 60
    "#{pad hours}:#{pad minutes}"
  end

  private

  def pad(number)
    number.to_i.to_s.rjust 2, '0'
  end
end

class Block
  include Comparable
  attr_accessor :start, :finish

  def initialize(str, day)
    start_str, finish_str = str.split '-'

    start_ary  = start_str.split(':')
    finish_ary = finish_str.split(':')

    @start  = Time.new(day.long_year, day.month, day.day, *start_ary)
    @finish = Time.new(day.long_year, day.month, day.day, *finish_ary)
    if @finish < @start
      @finish = @finish + 86400
    end
  end

  def to_s
    "#{format start}-#{format finish}"
  end

  def total
    (finish - start).to_i
  end

  def <=>(other)
    start <=> other.start
  end

  def include?(time)
    (start <= time) && (finish >= time)
  end

  private

  def format(time)
    time.strftime "%H:%M"
  end
end

class Day
  include Totals
  include Comparable

  attr_accessor :day, :month, :year, :blocks

  def initialize(date = '')
    @day, @month, @year = date.split('.').map &:to_i
  end

  def date
    "#{pad day}.#{pad month}.#{year}"
  end

  def to_s(options = {})
    blocks.sort!
    color = options.fetch :color, false
    blocks_str = blocks.join('   ')
    max_block_count = options.fetch :max_block_count, 0
    if block_count < max_block_count
      (max_block_count - block_count).times do
        blocks_str << '              '
      end
    end
    str = "#{date}   #{blocks_str}   Total: #{total_str}"
    if color
      return str.green if highlight?
      return str.blue if today?
    end
    str
  end

  def blocks
    @blocks ||= []
  end

  def block_count
    blocks.count
  end

  def add(*blocks)
    highlight!
    blocks.each do |block|

      self.blocks.reject! { |b|
        b.start > block.start && b.finish < block.finish }

      if self.blocks.any? { |b|
        b.start < block.start && b.finish > block.finish }
        next
      end

      if (overlap = self.blocks.find { |b| b.include?(block.finish) })
        overlap.start = block.start
        next
      end

      if (overlap = self.blocks.find { |b| b.include?(block.start) })
        overlap.finish = block.finish
        next
      end

      self.blocks << block
    end
  end

  def children
    blocks
  end

  def long_year
    year + 2000
  end

  def <=>(other)
    if month == other.month
      day <=> other.day
    else
      month <=> other.month
    end
  end

  def at?(time)
    (day == time.day) && (month == time.month) && (year == time.short_year)
  end

  def today?
    at? Time.now
  end

  def set(time)
    @day   = time.day
    @month = time.month
    @year  = time.short_year
  end

  def highlight!
    @highlight = true
  end

  def highlight?
    @highlight
  end
end

class Month
  include Totals

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

  attr_accessor :name, :days

  def self.name(month_nr)
    NAMES[month_nr]
  end

  def initialize(name)
    @name = name
  end

  def to_s(options = {})
    color = options.fetch :color, false
    days.sort!
    b_count = max_block_count
    "#{name}\r\n\r\n#{days.map { |d|
      d.to_s(:color => color, :max_block_count => b_count) }.join("\r\n")}\r\n\r\nTotal: #{total_str}"
  end

  def colored
    to_s :color => true
  end

  def children
    days
  end

  def max_block_count
    days.map(&:block_count).max
  end
end

if __FILE__ == $0
  option = ARGV.first
  this_folder = __FILE__[/\/.+\//]
  hours_folder = this_folder + 'hours/'
  if option == '-H' || option == '--hack'
    `open #{__FILE__}`
    exit
  end
  if option == '-h' || option == '--help'
    puts `cat #{this_folder}help.txt`
    exit
  end
  if option == '-u' || option == '--update'
    puts `cd #{this_folder} && git pull origin master`
    exit
  end
  if option == '-t' || option == '--test'
    puts `ruby #{this_folder}punch_test.rb`
    exit
  end
  now = Time.now
  month_nr = now.month
  month_nr += 1 if now.day > 21
  month_name = Month.name(month_nr)
  year = now.year
  filepath = "#{hours_folder}#{month_name}_#{year}.txt"
  unless File.exists? filepath
    File.open(filepath, "w") { |f| f.write "#{month_name.capitalize} #{year}" }
  end
  if option == '-b' || option == '--backup'
    ARGV.shift
    path = ARGV.shift
    error = `cp #{filepath} #{path}`
    puts error unless error.empty?
    exit
  end
  if option == '-e' || option == '--edit'
    `open #{filepath}`
    exit
  end
  if option == '-r' || option == '--raw'
    puts `cat #{filepath}`
    exit
  end
  File.open filepath, 'r+' do |file|
    month = BRFParser.new.parse(file.read)
    if option == '-f' || option == '--format'
      file.seek 0, IO::SEEK_SET
      file.truncate 0
      file.write month
      exit
    end
    unless ARGV.empty?
      if option == '-d' || option == '--day'
        ARGV.shift
        date = ARGV.shift
        unless (day = month.days.find { |d| d.date == date })
          day = Day.new date
          month.days << day
        end
      else
        unless (day = month.days.find { |d| d.at? now })
          day = Day.new
          day.set now
          month.days << day
        end
      end
      blocks = ARGV.map { |block_str| Block.new block_str, day }
      day.add *blocks
      file.seek 0, IO::SEEK_SET
      file.truncate 0
      file.write month
    end
    puts month.colored
  end
end
