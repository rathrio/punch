class Punch
  Option = Struct.new(:name, :description)

  class << self
    attr_accessor :options

    def options
      @options ||= []
    end

    def config
      load_from_config_file if @config.nil?
      @config
    end

    def load_from_config_file
      @config = new
      # Load config file.
      if File.exist?(config_file)
        begin
          eval File.read(config_file)
        rescue Exception => e
          message = "Something went wrong while trying to load ~/.punchrc:\n".pink
          message << "\n#{e}\n\n"
          message << "Proceeding with whatever settings could be loaded.\n".pink
          puts message
        end
      end
    end

    def config_file
      "#{Dir.home}/.punchrc"
    end

    def load_card(card)
      card_config = config.cards.fetch(card.to_sym) do
        puts "The card \"#{card}\" doesn't exist".pink
        exit
      end

      card_config.each do |k, v|
        config.send("#{k}=", v)
      end
    end

    # Generates smart accessor and predicate methods and remembers options to
    # inject them into .punchrc.
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

      attr_writer opt

      define_method opt do
        value = instance_variable_get("@#{opt}")
        return value unless value.nil?
        default_value
      end

      define_method "#{opt}?" do
        !!send(opt)
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
    File.expand_path('../hours', File.dirname(__FILE__))

  # @return [String]
  option :name,
    "Your full name.",
    "Spongebob Schwammkopf"

  # @return [String]
  option :title,
    "Title that appears in the BRF file.",
    ""

  # @return [Fixnum]
  option :hourly_pay,
    "How much you earn per hour.",
    0

  # @return [String]
  option :text_editor,
    "Which terminal application to use to edit files.",
    "open"

  # @return [Fixnum]
  option :hand_in_date,
    "After which day punch should generate the next month's BRF file.",
    20

  # @return [String]
  option :system_ruby,
    "Which ruby command to use to execute subcommands.",
    "ruby"

  # @return [Fixnum]
  option :monthly_goal,
    "How many hours you want to work per month.",
    68

  # @return [Boolean]
  option :group_weeks_in_interactive_mode,
    "Whether to add padding to group by week in the interactive editor.",
    true

  # @return [Boolean]
  option :regenerate_punchrc_after_udpate,
    "Whether to automatically regenerate ~/.punchrc with punch --update.",
    false

  # @return [Boolean]
  option :debug,
    "Print stack trace instead of user friendly hint.",
    false

  # @return [Hash]
  option :mailer_config,
    "BRFMailer configurations.",
    {
      :smtp_domain => "aarboard.ch",
      :smtp_server => "smtp.aarboard.ch",
      :smtp_port   => 465,
      :smtp_user   => "",
      :smtp_pw     => "",
      :receiver    => "",
      :cc          => "",
      :bcc         => "",
      :body        => ""
    }

  # @return [Hash]
  option :cards,
    "Register different punch cards.",
    {}

  # @return [#puts,#print]
  option :out,
    "Where to output stuff.",
    STDOUT,
    :hidden => true

  def config_file
    self.class.config_file
  end

  def reset!
    options.each { |option| send("#{option.name}=", nil) }
  end

  def generate_config_file
    File.open(config_file, "w") { |f| f.write config_string }
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

    "# Punch settings file. Use valid Ruby syntax or you shall be punished!\n"\
    "#\n"\
    "# To reset all settings run\n"\
    "#\n"\
    "#   $ punch --config-reset\n"\
    "#\n"\
    "# To regenerate this file while keeping your modifications and adding\n"\
    "# new options that might have been made available with an update run\n"\
    "#\n"\
    "#   $ punch --config-regenerate\n"\
    "#\n"\
    "# If you messed up so badly that punch won't even start up because of\n"\
    "# this config file and you don't know how to fix it, feel free to delete\n"\
    "# it and generate a new one with\n"\
    "#\n"\
    "#   $ punch --config\n"\
    "#\n"\
    "Punch.configure do |config|\n#{str}\nend"
  end
end
