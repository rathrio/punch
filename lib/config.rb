require 'singleton'

# Insecurely loads ~/.punchrc and provides settings as module accessors.
class Punch
  include Singleton

  Option = Struct.new(:name, :description)

  class << self
    attr_accessor :options
    def options
      @options ||= []
    end

    def option(opt, desc = '')
      options << Option.new(opt, desc)
      attr_accessor opt
    end

    def configure; yield instance; end

    def load(config_file = instance.config_file)
      eval File.read(config_file)
    end
  end

  option :hours_folder,
    "Where to look for the BRF files. Defaults to the hours folder in the punch directory."

  option :name,
    "Your full name."

  option :hourly_pay,
    "How much you earn per hour."

  option :text_editor,
    "Which terminal application to use to open files (i.e. for \"punch -e\" or \"punch -c\")"

  def hours_folder
    if @hours_folder.nil? || @hours_folder.end_with?('/')
      return @hours_folder
    end
    "#{@hours_folder}/"
  end

  def config_file
    "#{Dir.home}/.punchrc"
  end

  def text_editor
    @text_editor ||= 'open'
  end

  private

  def options
    self.class.options
  end

  def config_string
    str = options.map do |o|
      "  # #{o.description}\n  config.#{o.name} = #{send(o.name).inspect}"
    end.join("\n\n")
    <<-EOF
Punch.configure do |config|
#{str}
end
    EOF
  end
end
