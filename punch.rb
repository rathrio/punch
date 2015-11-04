#!/usr/bin/env ruby

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
require 'block_parser'

autoload :Tempfile, 'tempfile'
autoload :Merger, 'merger'
autoload :FileUtils, 'fileutils'
autoload :Editor, 'editor'
autoload :BRFMailer, 'brf_mailer'
autoload :Stats, 'stats'
autoload :MonthFiller, 'month_filler'

class PunchClock
  include OptionParsing

  VERSION_NAME = "The Baddest Man on the Planet"

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
    --coverage
    --day
    --diagram
    --doc
    --dry-run
    --edit
    --engine
    --format
    --full
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
    --review
    --stats
    --test
    --travis
    --trello
    --undo
    --update
    --version
    --whoami
    --yesterday
  )

  flag :dry_run

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
    return 0 if dry_run?
    file.rewind
    file.truncate 0
    file.write month
    file.rewind
  end

  def hand_in_date
    config.hand_in_date
  end

  def punch
    # Load card if one is active.
    Punch.load_card config.active_card if config.active_card?

    # First argument can be a card and may overwrite active card.
    card = @args.first
    if card =~ CARD_RGX
      Punch.load_card card
      @args.shift
    end

    switch "--dry-run" do
      dry_run!
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
      system "cd #{punch_folder} && #{config.text_editor} #{__FILE__}"
      exit
    end

    switch "-h", "--help" do
      begin
        f = Tempfile.new 'help'
        f.write(
          File.readlines(help_file).map do |l|
            l.start_with?('$') ? l.highlighted : l
          end.join
        )
        f.rewind
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

    switch "--diagram" do
      system "cd #{punch_folder} && "\
        "yard graph --protected --full --dependencies | "\
        "dot -T pdf -o diagram.pdf && "\
        "open diagram.pdf"
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

    switch "--coverage" do
      system "cd #{punch_folder} && "\
        "COVERAGE=true #{config.system_ruby} #{test_file} && "\
        "open coverage/index.html"
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

    switch "--review" do
      system "cd #{punch_folder} && pronto run"
      exit
    end

    switch "--travis" do
      system "open https://travis-ci.org/rathrio/punch"
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

    switch "--full" do
      @print_full_month = true
    end

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
        if yes?("The directory #{hours_folder.highlighted} does not exist. "\
          "Create it?")
          FileUtils.mkdir_p(hours_folder)
        else
          exit
        end
      end
      # Create empty BRF file for this month.
      File.open(brf_filepath, "w") do |f|
        f.write "#{month_name.capitalize} #{year}"
      end
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
      mailer.deliver if yes?("Do you want to send this mail?")
      exit
    end

    File.open brf_filepath, 'r+' do |file|
      @month = Month.from(file.read, month_nr, year)

      switch "--undo" do
        exit
      end

      switch "-f", "--format" do
        puts "Before formatting:\n".highlighted
        puts raw_brf
        @month.cleanup! :remove_ongoing_blocks => true
        write! file
        puts "\nAfter formatting:\n".highlighted
        puts raw_brf
        exit
      end

      switch "-C", "--console" do
        require 'pry'; binding.pry
        exit
      end

      switch "-i", "--interactive" do
        Editor.new(@month).run
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
        blocks = @args.map do |block_str|
          BlockParser.parse block_str, day
        end
        day.send action, *blocks

        # Cleanup in case we have empty days after a remove.
        month.cleanup! if action == :remove

        puts "#{MIDNIGHT_MADNESS_NOTES.sample.highlighted}\n" if day.unhealthy?

        write! file
      end

      # Print month with an empty current day if necessary.
      if month.days.none? { |d| d.at? now }
        today = Day.new
        today.set now
        month.add today
      end

      MonthFiller.new(month).fill! if print_full_month?

      system "clear" if config.clear_buffer_before_punch?
      puts month.fancy
    end

  rescue BRFParser::ParserError => e
    raise e if config.debug?
    puts "Couldn't parse #{brf_filepath.highlighted}."
  rescue Interrupt
    puts "\nExiting...".highlighted
    exit
  rescue => e
    raise e if config.debug?
    puts "That's not a valid argument, dummy.\n"\
      "Run #{"punch -h".highlighted} for help."
  end

  def config
    Punch.config
  end

  def edit_brf
    open brf_filepath
    exit
  end

  def print_version
    puts "#{VERSION_NAME.highlighted} #{version.highlighted} "\
      "released #{last_release}"
  end

  def raw_brf
    `cat #{brf_filepath}`
  end

  private

  def now
    @now ||= Time.now
  end

  def print_full_month?
    @print_full_month
  end

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

PunchClock.new(ARGV).punch if __FILE__ == $PROGRAM_NAME
