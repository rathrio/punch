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
require 'option_parsing'
require 'config'
require 'brf_parser'
require 'totals'
require 'attributes'
require 'block'
require 'day'
require 'month'

autoload :Tempfile, 'tempfile'
autoload :Merger, 'merger'
autoload :FileUtils, 'fileutils'
autoload :Editor, 'editor'
autoload :BRFMailer, 'brf_mailer'
autoload :Stats, 'stats'
autoload :FairRoundedTime, 'fair_rounded_time'

class PunchClock
  include OptionParsing

  VERSION_NAME = "Hydra Dynamite"

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

  # Card names are a restricted form of identifiers.
  CARD_RGX = /^(?!now)([a-z_][a-zA-Z0-9_]*)$/

  # For easy bash completion export.
  OPTIONS = %w(
    --backup
    --brf
    --card-config
    --cards
    --config
    --config-reset
    --config-update
    --console
    --doc
    --edit
    --engine
    --format
    --github
    --hack
    --help
    --interactive
    --log
    --mail
    --merge
    --next
    --options
    --previous
    --raw
    --remove
    --stats
    --test
    --trello
    --update
    --version
    --whoami
    --yesterday
  )

  attr_reader :path_to_punch, :month, :month_name, :year, :brf_filepath

  def initialize(args, path_to_punch = __FILE__)
    self.args = args
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
    file.write month.to_brf
    file.seek 0, IO::SEEK_SET
  end

  def hand_in_date
    config.hand_in_date
  end

  def punch

    # First argument can be a card.
    card = @args.first
    if card =~ CARD_RGX
      Punch.load_card card
      @args.shift
    end

    switch "--options" do
      puts OPTIONS.join(" ")
      exit
    end

    switch "--cards" do
      puts config.cards.keys.join(" ")
      exit
    end

    switch '--card-config' do
      puts "  #{literal(config.cards)}"
      exit
    end

    switch '--brf' do
      system "open #{hours_folder}"
      exit
    end

    switch "-H", "--hack" do
      system "cd #{punch_folder} && #{config.text_editor} ."
      exit
    end

    switch "-h", "--help" do
      begin
        f = Tempfile.new 'help'
        f.write File.readlines(help_file).map { |l|
          l.start_with?('$') ? l.highlighted : l }.join
        f.seek 0, IO::SEEK_SET
        system "less -R #{f.path}"
      ensure
        f.close
        exit
      end
    end

    switch "-D", "--doc" do
      system "cd #{punch_folder} && yard && open doc/index.html"
      exit
    end

    switch "-u", "--update" do
      puts "Fetching master branch...".highlighted
      system "cd #{punch_folder} && git pull origin master"
      print_version
      if config.regenerate_punchrc_after_udpate? &&
          File.exist?(config.config_file)
        config.generate_config_file
        puts "Updated ~/.punchrc.".highlighted
      end
      exit
    end

    switch "-t", "--test" do
      system "#{config.system_ruby} #{test_file}"
      exit
    end

    switch "-v", "--version" do
      print_version
      exit
    end

    switch "--engine" do
      puts "#{RUBY_ENGINE} #{RUBY_VERSION}"
      exit
    end

    flag "-l", "--log" do |n|
      system "cd #{punch_folder} && #{log(n)}"
      exit
    end

    switch "--trello" do
      system "open https://trello.com/b/xfN8alsq/punch"
      exit
    end

    switch "--github" do
      system "open https://github.com/rathrio/punch"
      exit
    end

    switch "--whoami" do
      puts "You are the sunshine of my life, #{config.name}.".highlighted
      exit
    end

    switch "-c", "--config" do
      open_or_generate_config_file
      exit
    end

    switch "--config-reset" do
      if yes? "Are you sure you want to reset ~/.punchrc?"
        config.reset!
        generate_and_open_config_file
      end
      exit
    end

    switch "--config-update" do
      generate_and_open_config_file
      exit
    end

    now = Time.now
    month_nr = now.month
    month_nr = (month_nr + 1) % 12 if now.day > hand_in_date

    switch "-n", "--next" do
      month_nr = (month_nr + 1) % 12
    end

    @year = (month_nr < now.month) ? now.year + 1 : now.year

    switch "-p", "--previous" do
      month_nr = (month_nr - 1) % 12
      month_nr = 12 if month_nr.zero?
      @year = (month_nr > now.month) ? now.year - 1 : now.year
    end

    @month_name = Month.name month_nr

    switch "-m", "--merge" do
      puts Merger.new(@args, month_nr, year).month
      exit
    end

    @brf_filepath = generate_brf_filepath month_name, year

    unless File.exist? brf_filepath
      # Create hours folder if necessary.
      unless File.directory? hours_folder
        if yes? "The directory #{hours_folder.highlighted} does not exist. Create it?"
          FileUtils.mkdir_p(hours_folder)
        else
          exit
        end
      end
      # Create empty BRF file for this month.
      File.open(brf_filepath, "w") { |f|
        f.write "#{month_name.capitalize} #{year}" }
    end

    switch "-b", "--backup" do
      path = @args.shift
      system "cp #{brf_filepath} #{path}"
      exit
    end

    switch "-e", "--edit" do
      edit_brf
    end

    switch "--raw" do
      puts raw_brf
      exit
    end

    switch "--mail" do
      mailer = BRFMailer.new(brf_filepath, month_name)
      # Print non-encoded version for confirmation.
      puts mailer.message false
      if yes?("Do you want to send this mail?")
        mailer.deliver
      end
      exit
    end

    File.open brf_filepath, 'r+' do |file|
      @month = Month.from(file.read, month_nr, year)

      switch "-f", "--format" do
        puts "Before formatting:\n".today_color
        puts raw_brf
        @month.cleanup!
        write! file
        puts "\nAfter formatting:\n".today_color
        puts raw_brf
        exit
      end

      switch "-C", "--console" do
        require 'pry'; binding.pry
        exit
      end

      switch "-i", "--interactive" do
        Editor.new(self).run
        write! file
      end

      switch "-s", "--stats" do
        puts Stats.new(month)
        exit
      end

      unless @args.empty?

        # The --day flag might set a day to edit.
        day = nil
        flag "-d", "--day" do |date|
          unless (day = month.days.find { |d| d.date == date })
            # Create that day if it doesn't exist yet.
            day = Day.from date
            month.add day
          end
        end

        # If not, auto-determine which day to edit.
        if day.nil?
          time_to_edit = now
          switch "-y", "--yesterday" do
            time_to_edit = now.previous_day
          end
          unless (day = month.days.find { |d| d.at? time_to_edit })
            # Create that day if it doesn't exist yet.
            day = Day.new
            day.set time_to_edit
            month.add day
          end
        end

        # Add or remove blocks.
        action = :add
        switch "-r", "--remove" do
          action = :remove
        end

        # Punch now! Replacing all "now"s with the current Time for convenience.
        rounded_time = case config.punch_now_rounder
          when :fair
            FairRoundedTime.now
          when :exact
            Time.now
          else
            FairRoundedTime.now
          end
        @args.map! { |a| a.gsub(/now/, rounded_time.strftime('%H:%M')) }

        blocks = @args.map { |block_str| Block.from block_str, day }
        day.send action, *blocks
        if day.unhealthy?
          puts "#{MIDNIGHT_MADNESS_NOTES.sample.highlighted}\n"
        end
        write! file
      end

      # Print month with an empty current day if necessary.
      if month.days.none? { |d| d.at? now }
        today = Day.new
        today.set now
        month.add today
      end
      puts month
    end

  rescue BRFParser::ParserError => e
    raise e if config.debug?
    puts "Couldn't parse #{brf_filepath.highlighted}."
  rescue Interrupt
    puts "\nExiting...".highlighted
    exit
  rescue => e
    raise e if config.debug?
    puts %{That's not a valid argument, dummy.\nRun #{"punch -h".highlighted} for help.}
  end

  def config
    Punch.config
  end

  def edit_brf
    open brf_filepath
    exit
  end

  def print_version
    puts "#{VERSION_NAME.highlighted} #{version.highlighted} released #{last_release}"
  end

  def raw_brf
    `cat #{brf_filepath}`
  end

  private

  def generate_brf_filepath(month_name, year)
    "#{hours_folder}/#{month_name}_#{year}.txt"
  end

  def open_or_generate_config_file
    if File.exist? config.config_file
      open config.config_file
    else
      if yes? "The ~/.punchrc file does not exist. Generate it?"
        generate_and_open_config_file
      end
    end
  end

  def generate_and_open_config_file
    config.generate_config_file
    open config.config_file
  end

  def open(file)
    system "#{config.text_editor} #{file}"
  end

  def log(n = nil)
    n = 10 if (n = n.to_i).zero?
    "git log"\
      " --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s'"\
      " --date=short"\
      " -n #{n}"
  end
end

if __FILE__ == $0
  PunchClock.new(ARGV).punch
end
