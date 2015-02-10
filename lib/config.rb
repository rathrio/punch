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

  option :hourly_pay,
    "How much you earn per hour.",
    0

  option :text_editor,
    "Which terminal application to use to open files (i.e. for \"punch -e\" or \"punch -c\")",
    "open"

  option :hand_in_date,
    "After which day punch should generate the next month's BRF file.",
    20

  option :system_ruby,
    "Which ruby command to use to execute subcommands.",
    "ruby"

  def initialize
    raise "Config already initialized" unless self.class.instance.nil?
    self.class.instance = self

    if File.exist?(config_file)
      eval File.read(config_file)
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

  private

  def options
    self.class.options
  end

  def config_string
    str = options.map do |o|
      "  # #{o.description}\n  config.#{o.name} = #{send(o.name).inspect}"
    end.join("\n\n")
    "Punch.configure do |config|\n#{str}\nend"
  end
end
