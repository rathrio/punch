if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    command_name 'MiniTest'
    add_filter '/test/'
  end
end
require 'minitest/autorun'
require 'minitest/pride'
require 'timecop'
require_relative '../punch'

TEST_CONFIG_FILE  = File.expand_path('.punchrc', File.dirname(__FILE__))
TEST_HOURS_FOLDER = File.expand_path('hours', File.dirname(__FILE__))

# STDOUT mock
module TestOut
  class << self
    attr_accessor :output
    def puts(str)
      self.output = str.to_s
    end
  end
end

# Stub config file
class Punch
  def config_file
    TEST_CONFIG_FILE
  end

  def cards
    {
      :test => {
        :hours_folder => TEST_HOURS_FOLDER,
        :out => TestOut,
        :debug => true,
        :clear_buffer_before_punch => false
      }
    }
  end
end

# Load test configurations.
Punch.config.reset!
Punch.load_card :test

# Provides some helper methods for integration tests. Also sets the current
# Time to 2pm on 28.01.2015 and automatically cleans up the test hours folder.
# When overriding #setup and #teardown, don't forget to call super.
class PunchTest < MiniTest::Test

  # Travel to 28.01.2015 2pm. So the current BRF month is February.
  def setup
    Timecop.freeze(Time.new(2015, 01, 28, 14))
  end

  def teardown
    Timecop.return
    clear_hours_folder
  end

  # Delete all BRF files in test hours folder.
  def self.clear_hours_folder
    system "rm #{TEST_HOURS_FOLDER}/*" unless `ls #{TEST_HOURS_FOLDER}`.empty?
  end

  def clear_hours_folder
    self.class.clear_hours_folder
  end

  # Path to test hours folder.
  def hours_folder
    TEST_HOURS_FOLDER
  end

  # Run punch clock. Mimics CLI.
  #
  #   punch "-d 20.01.2015 18:30-19"
  def punch(args = "")
    @clock = PunchClock.new(args.split)
    @clock.punch
  rescue SystemExit
    # Do nothing and move on like a baws. We don't wanna exit the test suite
    # when punch calls Kernel#exit.
  end

  # Recent test output.
  def output
    TestOut.output
  end

  # Content of current BRF file.
  def brf_content
    clock.raw_brf
  end

  # Current BRF file path.
  def brf_file
    clock.brf_filepath
  end

  # Write str to current BRF file.
  def brf_write(str)
    File.open(brf_file, 'w') { |f| f.write str }
  end

  # Assert that the brf file contains the str.
  def assert_punched(str)
    assert_includes brf_content, str
  end

  # Refute that the brf file contains the str.
  def refute_punched(str)
    refute_includes brf_content, str
  end

  # Assert that punch outputted the str.
  def assert_outputted(str)
    assert_includes output, str
  end

  # Most recently created punch clock instance.
  def clock
    punch if @clock.nil?
    @clock
  end

  def current_month
    clock.month
  end

  # Call a given block with the config hash in args temporarily loaded.
  #
  # @example Temporarily changing rounding strategy
  #
  #  config :punch_now_rounder => :exact do
  #    punch "now"
  #    assert_punched "13:41"
  #  end
  def config(args)
    old_config = Punch.config.clone

    args.each do |k, v|
      Punch.config.send "#{k}=", v
    end

    yield

  ensure
    Punch.config = old_config
  end

end

MiniTest.after_run { PunchTest.clear_hours_folder }
