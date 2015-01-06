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

class Module
  def flag(*names)
    names.each do |name|
      define_method "#{name}!" do
        instance_variable_set "@#{name}", true
      end
      define_method "#{name}?" do
        instance_variable_get "@#{name}"
      end
    end
  end
end

class Time
  def short_year
    strftime('%y').to_i
  end

  def previous_day
    self - 86400
  end

  def next_day
    self + 86400
  end
end

# https://stackoverflow.com/questions/1489183/colorized-ruby-output
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

  def yellow
    colorize 33
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
    Totals.format total
  end

  module_function

  def pad(number)
    number.to_i.to_s.rjust 2, '0'
  end

  def format(seconds)
    seconds = seconds.to_i
    hours   = seconds / 3600
    rest    = seconds - (hours * 3600)
    minutes = rest / 60
    "#{pad hours}:#{pad minutes}"
  end
end

class Block
  include Totals
  include Comparable
  attr_accessor :start, :finish, :day
  flag :over_midnight

  def initialize(str, day)
    @day = day
    start_str, finish_str = str.split '-'

    if start_str.empty? || finish_str.empty?
      raise ArgumentError, "\"#{str}\" is not valid Block"
    end

    start_ary  = start_str.split(':')
    finish_ary = finish_str.split(':')

    @start  = Time.new(day.long_year, day.month, day.day, *start_ary)
    @finish = Time.new(day.long_year, day.month, day.day, *finish_ary)
    if @finish < @start
      @finish = @finish.next_day
      day.unhealthy!
      over_midnight!
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
  flag :highlight, :unhealthy

  def initialize(date = '')
    @day, @month, @year = date.split('.').map &:to_i
  end

  def date
    "#{pad day}.#{pad month}.#{year}"
  end

  def to_time
    Time.new long_year, month, day
  end

  def time_on_next_day
    to_time.next_day
  end

  def to_s(options = {})
    blocks.sort!
    color = options.fetch :color, false
    blocks_str = blocks.join('   ')
    max_block_count = options.fetch :max_block_count, 0
    if block_count < max_block_count
      (max_block_count - block_count).times do
        # Padding before "Total:"
        blocks_str << '              '
      end
    end
    str = "#{date}   #{blocks_str}   Total: #{total_str}"
    if color
      return str.pink if highlight?
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
    if year == other.year
      if month == other.month
        day <=> other.day
      else
        month <=> other.month
      end
    else
      year <=> other.year
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
end

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

  attr_accessor :name, :days

  def self.name(month_nr)
    NAMES[month_nr]
  end

  def initialize(name)
    @name = name
  end

  def newline
    NEWLINE
  end

  def to_s(options = {})
    color = options.fetch :color, false
    days.sort!
    b_count = max_block_count
    "#{name}#{newline * 2}#{
      days.map { |d|
        d.to_s(:color => color, :max_block_count => b_count)
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
end

class Stats
  attr_accessor :month, :hourly_pay

  def initialize(month, hourly_pay = 0)
    @month = month
    @hourly_pay = hourly_pay
  end

  def longest_day
    Totals.format days.map(&:total).max
  end

  def longest_block
    Totals.format blocks.map(&:total).max
  end

  def most_blocks
    days.map(&:block_count).max || 0
  end

  def total_money_made
    "#{money_made month.total} CHF"
  end

  def late_nights
    blocks.count &:over_midnight?
  end

  def early_mornings
    blocks.count do |b|
      eight = eight_am b.day
      b.start <= eight && b.finish > eight
    end
  end

  def total_days
    days.count
  end

  def total_blocks
    blocks.count
  end

  def average_hours_per_day
    return 0 if days.empty?
    Totals.format(month.total / total_days)
  end

  def average_hours_per_block
    return 0 if blocks.empty?
    Totals.format(month.total / total_blocks)
  end

  def consecutive_days
    max = 0
    days[0..days.size - 2].each do |d|
      i = 1
      i += 1 while d = next_day(d)
      max = i if i > max
    end
    max
  end

  def to_s
    <<-EOS
#{label "Total hours"}#{month.total_str}
#{label "Money made"}#{total_money_made}
#{label "Total days"}#{total_days}
#{label "Total blocks"}#{total_blocks}
#{label "Avg hours per day"}#{average_hours_per_day}
#{label "Avg hours per block"}#{average_hours_per_block}
#{label "Longest day"}#{longest_day}
#{label "Longest block"}#{longest_block}
#{label "Most blocks in day"}#{most_blocks}
#{label "Late nights"}#{late_nights}
#{label "Early mornings"}#{early_mornings}
#{label "Consecutive days"}#{consecutive_days}
    EOS
  end

  private

  def next_day(day)
    days.find { |d| d.at? day.time_on_next_day }
  end

  def days
    @days ||= month.days
  end

  def blocks
    @blocks ||= month.blocks
  end

  def money_made(seconds)
    (hourly_pay / 3600.0 * seconds).round 2
  end

  def label(str)
    "#{str}:".ljust(23).blue
  end

  def eight_am(day)
    Time.new(day.long_year, day.month, day.day, 8)
  end
end

class PunchClock
  HAND_IN_DATE = 20

  MIDNIGHT_MADNESS_NOTES = [
    "Get some sleep!",
    "Don't you have any hobbies?",
    "Get some rest, (wo)man...",
    "You should go to bed.",
    "That can't be healthy.",
    "You might need therapy.",
    "All work and no play makes Jack a dull boy.",
    "You need to get your priorities straight.",
    "Work-life balance. Ever heard of it?",
    "Did you know that the average adult needs 7-8 hours of sleep?"
  ]

  attr_accessor :args, :path_to_punch, :month

  def initialize(args, path_to_punch = __FILE__)
    @args = args
    @path_to_punch = path_to_punch
  end

  def punch_folder
    @punch_folder ||= path_to_punch[/\/.+\//]
  end

  def hours_folder
    @hours_folder ||= "#{punch_folder}hours/"
  end

  def version
    @version ||= `cd #{punch_folder} && git rev-parse --short HEAD`.chomp
  end

  def last_release
    @last_release ||= `cd #{punch_folder} && git log -1 --format=%cr HEAD`.chomp
  end

  def help_file
    "#{punch_folder}help.txt"
  end

  def test_file
    "#{punch_folder}punch_test.rb"
  end

  def write!(file)
    file.seek 0, IO::SEEK_SET
    file.truncate 0
    file.write month
  end

  def hand_in_date
    HAND_IN_DATE
  end

  def midnight_madness_notes
    MIDNIGHT_MADNESS_NOTES
  end

  def punch
    option = @args.first
    if option == '-H' || option == '--hack'
      `open #{__FILE__}`
      exit
    end
    if option == '-h' || option == '--help'
      begin
        require 'tempfile'
        f = Tempfile.new 'help'
        f.write File.readlines(help_file).map { |l|
          l.start_with?('$') ? l.blue : l }.join
        f.seek 0, IO::SEEK_SET
        system "less -R #{f.path}"
      ensure
        f.close
        exit
      end
    end
    if option == '-u' || option == '--update'
      system "cd #{punch_folder} && git pull origin master"
      exit
    end
    if option == '-t' || option == '--test'
      system "ruby #{test_file}"
      exit
    end
    if option == '-v' || option == '--version'
      puts "#{version.blue} released #{last_release}"
      exit
    end
    now = Time.now
    month_nr = now.month
    month_nr = (month_nr + 1) % 12 if now.day > hand_in_date
    if option == '-n' || option == '--next'
      @args.shift
      month_nr = (month_nr + 1) % 12
      option = @args.first
    end
    year = (month_nr < now.month) ? now.year + 1 : now.year
    if option == '-p' || option == '--previous'
      @args.shift
      month_nr = (month_nr - 1) % 12
      month_nr = 12 if month_nr.zero?
      year = (month_nr > now.month) ? now.year - 1 : now.year
      option = @args.first
    end
    month_name = Month.name month_nr
    filepath = brf_file_path month_name, year
    unless File.exists? filepath
      File.open(filepath, "w") { |f|
        f.write "#{month_name.capitalize} #{year}" }
    end
    if option == '-b' || option == '--backup'
      @args.shift
      path = @args.shift
      system "cp #{filepath} #{path}"
      exit
    end
    if option == '-e' || option == '--edit'
      `open #{filepath}`
      exit
    end
    if option == '-r' || option == '--raw'
      system "cat #{filepath}"
      exit
    end
    File.open filepath, 'r+' do |file|
      @month = BRFParser.new.parse(file.read)
      if option == '-f' || option == '--format'
        write! file
        exit
      end
      if option == '-c' || option == '--console'
        require 'pry'; binding.pry
        exit
      end
      if option == '-s' || option == '--stats'
        @args.shift
        puts Stats.new(month, @args.shift.to_i)
        exit
      end
      unless @args.empty?
        if option == '-d' || option == '--day'
          @args.shift
          date = @args.shift
          unless (day = month.days.find { |d| d.date == date })
            day = Day.new date
            month.days << day
          end
        else
          time_to_edit = if (option == '-y' || option == '--yesterday')
            @args.shift
            now.previous_day
          else
            now
          end
          unless (day = month.days.find { |d| d.at? time_to_edit })
            day = Day.new
            day.set time_to_edit
            month.days << day
          end
        end
        blocks = @args.map { |block_str| Block.new block_str, day }
        day.add *blocks
        if day.unhealthy?
          puts "#{midnight_madness_notes.sample.pink}\n"
        end
        write! file
      end
      puts month.colored
    end
  end

  private

  def brf_file_path(month_name, year)
    "#{hours_folder}#{month_name}_#{year}.txt"
  end
end

PunchClock.new(ARGV).punch if __FILE__ == $0
