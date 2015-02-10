#!/usr/bin/env ruby

# The MIT License (MIT)
#
# Copyright (c) 2015 Rathesan Iyadurai
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

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require 'core_extensions'
require 'config'
require 'brf_parser'
require 'totals'
require 'block'
require 'day'
require 'month'

class PunchClock
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

  attr_accessor :args, :path_to_punch, :month, :brf_filepath

  def initialize(args, path_to_punch = __FILE__)
    @args = args
    @path_to_punch = path_to_punch
  end

  def punch_folder
    @punch_folder ||= File.dirname(path_to_punch)
  end

  def hours_folder
    @hours_folder ||= config.hours_folder
  end

  def version
    @version ||= `cd #{punch_folder} && git rev-parse --short HEAD`.chomp
  end

  def last_release
    @last_release ||= `cd #{punch_folder} && git log -1 --format=%cr HEAD`.chomp
  end

  def help_file
    "#{punch_folder}/help.txt"
  end

  def test_file
    "#{punch_folder}/test/punch_test.rb"
  end

  def write!(file)
    file.seek 0, IO::SEEK_SET
    file.truncate 0
    file.write month
  end

  def hand_in_date
    config.hand_in_date
  end

  def midnight_madness_notes
    MIDNIGHT_MADNESS_NOTES
  end

  def punch
    option = @args.first
    if option == '-H' || option == '--hack'
      system "cd #{punch_folder} && #{config.text_editor} ."
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
    if option == '-D' || option == '--doc'
      system "cd #{punch_folder} && yard && open doc/index.html"
      exit
    end
    if option == '-u' || option == '--update'
      system "cd #{punch_folder} && git pull origin master"
      exit
    end
    if option == '-t' || option == '--test'
      system "#{config.system_ruby} #{test_file}"
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
    @brf_filepath = generate_brf_filepath month_name, year
    unless File.exist? brf_filepath
      File.open(brf_filepath, "w") { |f|
        f.write "#{month_name.capitalize} #{year}" }
    end
    if option == '-b' || option == '--backup'
      @args.shift
      path = @args.shift
      system "cp #{brf_filepath} #{path}"
      exit
    end
    edit_brf if option == '-e' || option == '--edit'
    if option == '-r' || option == '--raw'
      system "cat #{brf_filepath}"
      exit
    end
    File.open brf_filepath, 'r+' do |file|
      @month = BRFParser.new.parse(file.read)
      @month.number = month_nr
      @month.year   = year
      if option == '-f' || option == '--format'
        write! file
        exit
      end
      if option == '-c' || option == '--config'
        open_or_generate_config_file
        exit
      end
      if option == '--config-reset'
        puts "Are you sure you want to reset ~/.punchrc? (y|n)"
        if STDIN.gets.chomp == 'y'
          config.reset!
          generate_and_open_config_file
        end
        exit
      end
      if option == '--config-regenerate'
        generate_and_open_config_file
        exit
      end
      if option == '-C' || option == '--console'
        require 'pry'; binding.pry
        exit
      end
      if option == '-i' || option == '--interactive'
        @args.shift
        require 'editor'; Editor.new(self).run
        write! file
      end
      if option == '-s' || option == '--stats'
        @args.shift
        require 'stats'
        hourly_pay = (@args.shift || config.hourly_pay).to_i
        puts Stats.new(month, hourly_pay)
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
      # Add today if necessary
      if month.days.none? { |d| d.at? now }
        today = Day.new
        today.set now
        month.days << today
      end
      puts month.colored
    end
  end

  def config
    @config ||= Punch.new
  end

  def edit_brf
    open brf_filepath
    exit
  end

  private

  def puts(str)
    config.out.puts str
  end

  def open_or_generate_config_file
    if File.exist? config.config_file
      open config.config_file
    else
      puts "The ~/.punchrc file does not exist. Generate it? (y|n)"
      generate_and_open_config_file if STDIN.gets.chomp == 'y'
    end
  end

  def generate_and_open_config_file
    config.generate_config_file
    open config.config_file
  end

  def open(file)
    system "#{config.text_editor} #{file}"
  end

  def generate_brf_filepath(month_name, year)
    "#{hours_folder}/#{month_name}_#{year}.txt"
  end
end

if __FILE__ == $0
  PunchClock.new(ARGV).punch
end
