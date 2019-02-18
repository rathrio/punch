# frozen_string_literal: true

class Punch
  Option = Struct.new(:name, :description)

  class << self
    attr_writer :config

    def options
      @options ||= []
    end

    def config
      init_and_load_from_config_file if @config.nil?
      @config
    end

    def init_and_load_from_config_file
      # rubocop:disable RescueException
      @config = new
      return unless File.exist?(config_file)
      begin
        load config_file
      rescue Exception => e
        message = "Something went wrong while trying to load ~/.punchrc:\n".
          highlighted
        message << "\n#{e}\n\n"
        message << "Proceeding with whatever settings could be loaded.\n".
          highlighted
        puts message
      end
      # rubocop:enable RescueException
    end

    def config_file
      "#{Dir.home}/.punchrc"
    end

    def load_card(card)
      card_config = config.cards.fetch(card.to_sym) do
        puts "The card \"#{card}\" doesn't exist".highlighted
        exit
      end

      card_config.each do |k, v|
        config.send("#{k}=", v)
      end
    end

    # Generates smart accessor and predicate methods and remembers options to
    # inject them into .punchrc.
    #
    # @param args [Hash]
    # @option args [Boolean] :hidden (false) whether to hide this option
    #   .punchrc.
    # @option args [Boolean] :path (false) whether to treat the values as file
    #   paths. Punch will for instance substitute '~' with ENV['home'].
    #
    # @example Generating a boolean option with default value `false`
    #
    #   option :adult                            # Name of the option
    #     "Whether you have hair on your face.", # Short description
    #     false                                  # Default value
    #
    #   # Generates following methods on the config instance:
    #   Punch.config.adult        # => false
    #   Punch.config.adult?       # => false
    #   Punch.config.adult = true
    #   Punch.config.adult?       # => true
    #
    #   # And will add following option to .punchrc with the given description
    #   # as a comment:
    #
    #   # Whether you have hair on your face.
    #   config.adult = false
    #
    def option(opt, desc, default_value, args = {})
      options << Option.new(opt, desc) unless args.fetch(:hidden, false)

      if args.fetch(:path, false)
        define_method "#{opt}=" do |opt_value|
          instance_variable_set "@#{opt}", opt_value.to_s.absolute_path
        end
      else
        attr_writer opt
      end

      define_method opt do
        value = instance_variable_get("@#{opt}")
        return value unless value.nil?
        default_value
      end

      define_method "#{opt}?" do
        send(opt)
      end

      define_method "_default_#{opt}" do
        default_value
      end
    end

    def configure
      yield config
    end

    private :new
  end

  # @return [String]
  option :hours_folder,
    "Where to look for the BRF files.",
    File.expand_path('../hours', File.dirname(__FILE__)),
    :path => true

  # @return [String]
  option :name,
    "Your full name.",
    ""

  # @return [String]
  option :title,
    "Title that appears in the BRF file.",
    ""

  # @return [Symbol]
  option :language,
    "What language to display month names in. Use two char language codes.",
    :en

  # @return [String]
  option :default_args,
    "Arguments to pass by default. e.g. '-y' to always punch yesterday.",
    ""

  # @return [Fixnum]
  option :hourly_pay,
    "How much you earn per hour.",
    0

  # @return [String]
  option :text_editor,
    "Which terminal application to use to edit files.",
    OS.open_cmd

  # @return [Fixnum]
  option :hand_in_date,
    "After which day to switch to next month file (1..31).",
    31

  # @return [Fixnum]
  option :monthly_goal,
    "How many hours you want to work per month.",
    68

  # @return [Float]
  option :daily_goal,
    "How many hours you want to work per day.",
    8.4

  # @return [Symbol]
  option :goal_type,
    "Whether you want the stats to use the daily or monthly goal.",
    :monthly

  # @return [Array]
  option :workdays,
    "Which days you work on. Used for stats.",
    [:monday, :tuesday, :wednesday, :thursday, :friday]

  # @return [Array]
  option :ignore_tags,
    "Keywords in comments that the stats will consider to ignore days.",
    ["ignore", "sick", "vacation", "holiday"]

  # @return [Symbol]
  option :totals_format,
    "How to render totals (:digital or :decimal).",
    :digital

  # @return [Boolean]
  option :colors_enabled,
    "Whether to color certain output.",
    true

  # @return [Fixnum]
  option :highlight_color_code,
    "Which color to use for highlighting important text.",
    35

  # @return [Fixnum]
  option :today_color_code,
    "Which color to use for highlighting the current date.",
    34

  # @return [Boolean]
  option :group_weeks_in_interactive_mode,
    "Whether to group weeks in --full and --interactive mode",
    true

  # @return [Symbol]
  option :punch_now_rounder,
    "Rounding strategy applied when substituting \"now\" (:fair or :exact).",
    :fair

  # @return [Fixnum]
  option :punch_now_minute_precision,
    "What precision (minutes) to round to.",
    5

  # @return [Boolean]
  option :regenerate_punchrc_after_udpate,
    "Whether to automatically regenerate ~/.punchrc with punch --update.",
    false

  # @return [Boolean]
  option :clear_buffer_before_punch,
    "Clear terminal buffer before printing month.",
    false

  # @return [Boolean]
  option :pager,
    "Whether to automatically open long output with pager.",
    true

  # @return [Boolean]
  option :debug,
    "Print stack trace instead of user friendly hint.",
    false

  # @return [String]
  option :system_ruby,
    "Which ruby command to use to execute subcommands.",
    "ruby",
    :path => true

  # @return [Hash]
  option :mailer_config,
    "BRFMailer configurations.",
    {
      :smtp_domain => "example.com",
      :smtp_server => "smtp.example.com",
      :smtp_port   => 465,
      :smtp_user   => "spongebob@example.com",
      :smtp_pw     => "gary4ever",
      :receiver    => "mr_krabs@example.com",
      :bcc         => "",
      :body        => "Hi Mr Krabs, you'll find my hours attached. Cheers S."
    }

  # @return [Hash]
  option :cards,
    "Register different punch cards.",
    {}

  # @return [Symbol,NilClass]
  option :active_card,
    "Which card to load by default. Set this to nil to load no card.",
    nil

  # @return [#puts,#print]
  option :out,
    "Where to output stuff.",
    STDOUT,
    :hidden => true

  option :in,
    "Where to get user input from.",
    STDIN,
    :hidden => true

  def config_file
    self.class.config_file
  end

  def reset!
    options.each { |option| send("#{option.name}=", nil) }
  end

  def generate_config_file
    File.open(config_file, "w:UTF-8") { |f| f.write config_string }
  end

  private

  def puts(str = '')
    out.puts str
  end

  def options
    self.class.options
  end

  def config_string
    str = options.map do |o|
      "  # #{o.description}\n  config.#{o.name} = #{literal(send(o.name))}"
    end.join("\n\n")

    "# vi: ft=ruby\n"\
    "#\n"\
    "# Punch settings file.\n"\
    "#\n"\
    "# To reset all settings run\n"\
    "#\n"\
    "#   $ punch --config-reset\n"\
    "#\n"\
    "# To update this file while keeping your modifications and adding\n"\
    "# new options from an update run\n"\
    "#\n"\
    "#   $ punch --config-update\n"\
    "#\n"\
    "# If you messed up so badly that punch won't even start up because of\n"\
    "# this config file and you don't know how to fix it, feel free to\n"\
    "# delete it and generate a new one with\n"\
    "#\n"\
    "#   $ punch --config\n"\
    "#\n"\
    "Punch.configure do |config|\n#{str}\nend"
  end
end
