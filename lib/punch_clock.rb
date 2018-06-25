# frozen_string_literal: true

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
  ].freeze

  # Card names are a restricted form of identifiers.
  CARD_RGX = /^(?!now)([a-z_][a-zA-Z0-9_]*)$/

  # The options listed here can be tab completed.
  OPTIONS = %w(
    --backup
    --brf
    --card-config
    --cards
    --clear-comment
    --clear-tags
    --comment
    --config
    --config-reset
    --config-update
    --console
    --coverage
    --day
    --debug
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
    --hours
    --interactive
    --log
    --mail
    --merge
    --month
    --next
    --options
    --previous
    --profile
    --raw
    --remove
    --reset-config
    --review
    --stats
    --tag
    --test
    --travis
    --trello
    --undo
    --update
    --update-config
    --version
    --whoami
    --year
    --yesterday
  ).freeze

  attr_reader :month, :month_name, :year, :brf_filepath

  flag :dry_run, :print_full_month, :debug, :profile

  def initialize(args)
    self.args = args
  end

  def punch_folder
    @punch_folder ||= File.dirname(PUNCH_FILE)
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

    # Load passed cards.
    while CARD_RGX =~ @args.first
      card = @args.shift
      Punch.load_card card
    end

    # Prepend default arguments.
    unless config.default_args.empty?
      @args.unshift(*config.default_args.split(' '))
    end

    switch "--profile" do
      profile!
    end

    if profile?
      require 'ruby-prof'
      RubyProf.start
    end

    switch "--dry-run" do
      dry_run!
    end

    switch "--debug" do
      debug!
    end

    switch "--options" do
      puts OPTIONS.join("\n")
      exit
    end

    switch "--cards" do
      puts config.cards.keys.join("\n")
      exit
    end

    switch '--card-config' do
      puts "  #{literal(config.cards)}"
      exit
    end

    switch '--hours', '--brf' do
      system "#{config.text_editor} #{hours_folder}"
      exit
    end

    switch "--hack" do
      system "cd #{punch_folder} && #{config.text_editor} #{PUNCH_FILE}"
      exit
    end

    switch "-h", "--help" do
      generate_and_open_help_file
      exit
    end

    switch "--doc" do
      system "cd #{punch_folder} && yard && #{OS.open_cmd} doc/index.html"
      exit
    end

    switch "--diagram" do
      generate_and_open_dependency_diagram
      exit
    end

    switch "-u", "--update" do
      update_punch
      exit
    end

    switch "--test" do
      system "#{config.system_ruby} #{test_file}"
      exit
    end

    switch "--coverage" do
      generate_and_open_coverage
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
      OS.open "https://travis-ci.org/rathrio/punch"
      exit
    end

    switch "--trello" do
      OS.open "https://trello.com/b/xfN8alsq/punch"
      exit
    end

    switch "--github" do
      OS.open "https://github.com/rathrio/punch"
      exit
    end

    switch "--whoami" do
      msg = "You are the sunshine of my life"
      msg = "#{msg}, #{config.name}" unless config.name.empty?
      puts "#{msg}.".highlighted
      exit
    end

    switch "-c", "--config" do
      open_or_generate_config_file
      exit
    end

    switch "--reset-config", "--config-reset" do
      if yes? "Are you sure you want to reset ~/.punchrc?"
        config.reset!
        generate_and_open_config_file
      end
      exit
    end

    switch "--update-config", "--config-update" do
      generate_and_open_config_file
      exit
    end

    switch "--ful", "--full" do
      print_full_month!
    end

    month_year = MonthYear.new(:month => now.month, :year => now.year)
    month_year = month_year.next if now.day > hand_in_date

    switch "-n", "--next" do
      month_year = month_year.next
    end

    switch "-p", "--previous" do
      month_year = month_year.prev
    end

    flag "-m", "--month" do |month|
      month, year = month.split(".")
      year = month_year.year if year.nil?
      month_year = MonthYear.new(:month => month, :year => year)
    end

    flag "--year" do |year|
      month_year = MonthYear.new(:month => month_year.month, :year => year)
    end

    @month_name = MonthNames.name month_year.month

    switch "--merge" do
      puts Merger.new(@args, month_year).month
      exit
    end

    @brf_filepath = generate_brf_filepath(month_year)

    flag "-b", "--backup" do |path|
      system "cp #{brf_filepath} #{path}"
      exit
    end

    flag "-e", "--edit" do |application|
      edit_brf application
    end

    switch "--raw" do
      puts raw_brf
      exit
    end

    switch "--mail" do
      mailer = BRFMailer.new(brf_filepath, month_name)
      # Print non-encoded version for confirmation.
      puts mailer.message false
      mailer.deliver if yes?("Do you want to send this mail?".highlighted)
      exit
    end

    File.open brf_filepath, 'r+' do |file|
      @month = Month.from(file.read, month_year.month, month_year.year)

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

      switch "--console" do
        # rubocop:disable Debugger
        require 'pry'
        binding.pry
        # rubocop:enable Debugger
        exit
      end

      switch "-i", "--interactive" do
        @month = Editor.new(@month).run
        write! file
      end

      switch "-s", "--stats" do
        puts Stats.new(month)
        exit
      end

      unless @args.empty?
        day = nil

        # The --day flag might set a day to edit.
        flag "-d", "--day" do |date|
          day = month.find_or_create_day_by_date(date)
        end

        # If not, auto-determine which day to edit.
        if day.nil?
          time_to_edit = now
          switch "-y", "--yesterday" do
            time_to_edit = now.prev_day
          end
          unless (day = month.days.find { |d| d.at? time_to_edit })
            # Create that day if it doesn't exist yet.
            day = Day.new
            day.set time_to_edit
            month.add day
          end
        end

        flag "-t", "--tag", "--comment" do |comment|
          comment = gets_tmp('comment', day.comment) if comment.nil?
          day.comment = comment
        end

        switch "--clear-tags", "--clear-comment" do
          day.comment = nil
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

        if day.unhealthy? && action == :add
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

      system "clear" if config.clear_buffer_before_punch?

      if print_full_month?
        puts month.full
      else
        puts month.fancy
      end
    end
  rescue BRFParser::ParserError => e
    raise e if debug_mode?
    puts "Couldn't parse #{brf_filepath.highlighted}."
  rescue Interrupt
    puts "\nExiting...".highlighted
    exit
  rescue => e
    raise e if debug_mode?
    puts "Unknown arguments.\n"\
      "Pass #{"--help".highlighted} for a list of options or retry with"\
      " #{"--debug".highlighted} to get a stacktrace."
  ensure
    if profile?
      result = RubyProf.stop
      printer = RubyProf::FlatPrinter.new(result)
      puts "\nProfiler Results\n".highlighted
      printer.print(STDOUT)
    end
  end

  def config
    Punch.config
  end

  # @param application [String] which application to open file with,
  #   e.g. "TextEdit"
  def edit_brf(application = nil)
    open brf_filepath, application
    exit
  end

  def print_version
    puts "#{VERSION_NAME.highlighted} #{version.highlighted} "\
      "released #{last_release}"
  end

  def raw_brf
    File.read(brf_filepath)
  end

  private

  def debug_mode?
    debug? || config.debug?
  end

  def now
    @now ||= Date.today
  end

  def generate_brf_filepath(month_year)
    filepath = "#{hours_folder}/#{month_year.year}-#{month_year.month}.txt"
    return filepath if File.exist?(filepath)

    german_month_name = MonthNames.name(month_year.month, :de).sub("ä", "ae")
    legacy_filepath = "#{hours_folder}/#{german_month_name}_#{month_year.year}.txt"
    if File.exist?(legacy_filepath)
      FileUtils.mv(legacy_filepath, filepath)
      return filepath
    end

    # Create hours folder if necessary
    unless File.directory? hours_folder
      if yes?("The directory #{hours_folder.highlighted} does not exist. "\
          "Create it?")
        FileUtils.mkdir_p(hours_folder)
      else
        exit
      end
    end

    # Create empty BRF file for this month.
    File.open(filepath, "w") do |f|
      f.write "#{month_name.capitalize} #{month_year.year}"
    end

    filepath
  end

  def open_or_generate_config_file
    if File.exist? config.config_file
      open config.config_file
    elsif yes? "The ~/.punchrc file does not exist. Generate it?"
      generate_and_open_config_file
    end
  end

  def generate_and_open_config_file
    config.generate_config_file
    open config.config_file
  end

  def open(file, application = nil)
    if application.nil?
      system "#{config.text_editor} #{file}"
    else
      system %{#{OS.open_cmd} -a "#{application}" #{file}}
    end
  end

  def log(n = nil)
    n = 10 if (n = n.to_i).zero?
    "git log"\
      " --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s'"\
      " --date=short"\
      " -n #{n}"
  end

  def generate_and_open_help_file
    f = Tempfile.new 'help'
    f.write(
      File.readlines(help_file).map do |l|
        l.start_with?('$') ? l.highlighted : l
      end.join
    )
    f.rewind
    if config.pager? && OS.pager
      system "#{OS.pager} -R #{f.path}"
    else
      puts f.read
    end
  ensure
    f.close
  end

  def generate_and_open_dependency_diagram
    system "cd #{punch_folder} && "\
      "yard graph --protected --full --dependencies | "\
      "dot -T pdf -o diagram.pdf && "\
      "#{OS.open_cmd} diagram.pdf"
  end

  def update_punch
    puts "Fetching master branch...".highlighted
    system "cd #{punch_folder} && git pull origin master"

    print_version

    if config.regenerate_punchrc_after_udpate? &&
        File.exist?(config.config_file)

      config.generate_config_file
      puts "Updated ~/.punchrc.".highlighted
    end
  end

  def generate_and_open_coverage
    system "cd #{punch_folder} && "\
      "PUNCH_COVERAGE=true #{config.system_ruby} #{test_file} && "\
      "#{OS.open_cmd} coverage/index.html"
  end
end
