require_relative 'config'

class OptionParsingTest < MiniTest::Test

  class CLI
    include OptionParsing

    attr_reader :age, :weight, :id

    def initialize(args)
      self.args = args
    end

    def yesterday?
      @yesterday
    end

    def verbose?
      @verbose
    end

    def run
      flag "--weight" do |weight|
        @weight = weight
      end

      switch "-y", "--yesterday" do
        @yesterday = true
      end

      switch "-v", "--verbose" do
        @verbose = true
      end

      flag "-a", "--age" do |arg|
        @age = arg.to_i
      end

      flag "-i", "--id", required: true do |id|
        @id = id.to_i
      end
    end
  end

  def test_switches
    cli = CLI.new(["--yesterday"])
    cli.run
    assert cli.yesterday?, "switch wasn't parsed"

    cli = CLI.new(["-y"])
    cli.run
    assert cli.yesterday?, "switch wasn't parsed"
  end

  def test_flags
    cli = CLI.new(["--age", "15"])
    cli.run
    assert_equal 15, cli.age
    assert_empty cli.args

    cli = CLI.new(["-a", "15"])
    cli.run
    assert_equal 15, cli.age
    assert_empty cli.args
  end

  def test_switches_with_flags
    cli = CLI.new(["-a", "15", "--yesterday"])
    cli.run

    assert_equal 15, cli.age
    assert cli.yesterday?, "switch wasn't parsed"
    assert_empty cli.args
  end

  def test_order_doesnt_matter
    cli = CLI.new(["--yesterday", "--age", "15"])
    cli.run

    assert_equal 15, cli.age
    assert cli.yesterday?, "switch wasn't parsed"
    assert_empty cli.args
  end

  def test_passing_multiple_switches
    cli = CLI.new(["-vy"])
    cli.run

    assert cli.verbose?, 'multi switch parsing failed'
    assert cli.yesterday?, 'multi switch parsing failed'
    assert_empty cli.args
  end

  def test_optional_flag
    cli = CLI.new(["--weight", "--yesterday"])
    cli.run

    assert_nil cli.weight
    assert cli.yesterday?, 'wrongly consumed switch as optional flag argument'
  end

  def test_required_flag
    assert_raises(OptionParsing::MissingRequiredFlagError) do
      cli = CLI.new(["-i"])
      cli.run
    end

    cli = CLI.new(["-i", "42"])
    cli.run

    assert_equal 42, cli.id
  end
end
