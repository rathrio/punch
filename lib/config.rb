# Insecurely loads ~/.punchrc on initialize and provides the settings as
# accessors on Punch.instance.
class Punch
  Option = Struct.new(:name, :description)

  class << self
    attr_accessor :options, :instance

    def options
      @options ||= []
    end

    def option(opt, desc, default_value = nil)
      options << Option.new(opt, desc)
      attr_writer opt
      define_method opt do
        instance_variable_get("@#{opt}") || default_value
      end
    end

    def configure; yield instance; end
  end

  option :hours_folder,
    "Where to look for the BRF files.",
    File.expand_path('../hours', File.dirname(__FILE__))

  option :name,
    "Your full name.",
    "Spongebob Schwammkopf"

  option :title,
    "Titles that appears in the BRF file.",
    ""

  option :hourly_pay,
    "How much you earn per hour.",
    0

  option :text_editor,
    "Which terminal application to use to edit files.",
    "open"

  option :hand_in_date,
    "After which day punch should generate the next month's BRF file.",
    20

  option :system_ruby,
    "Which ruby command to use to execute subcommands.",
    "ruby"

  option :monthly_goal,
    "How many hours you want to work per month.",
    68

  option :debug,
    "Print stack trace instead of user friendly hint.",
    false

  option :cards,
    "Register different punch cards.",
    {}

  def initialize(card = nil)
    return self.class.instance unless self.class.instance.nil?

    self.class.instance = self

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

    # Load custom card configuration.
    if card
      card_config = cards.fetch(card.to_sym) do
        puts "The card \"#{card}\" doesn't exist".pink
        exit
      end

      card_config.each do |k, v|
        send("#{k}=", v)
      end
    end
  end

  def reset!
    options.each { |option| send("#{option.name}=", nil) }
  end

  def config_file
    "#{Dir.home}/.punchrc"
  end

  def generate_config_file
    File.open(config_file, "w") { |f| f.write config_string }
  end

  def out
    STDOUT
  end

  def debug?
    debug
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
