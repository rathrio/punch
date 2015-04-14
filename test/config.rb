TEST_CONFIG_FILE  = File.expand_path('.punchrc', File.dirname(__FILE__))
TEST_HOURS_FOLDER = File.expand_path('hours', File.dirname(__FILE__))

# STDOUT mock
module TestOut
  class << self
    attr_accessor :output
    def puts(str)
      self.output = str
    end
  end
end

# Stub some config
class Punch
  def config_file
    TEST_CONFIG_FILE
  end

  def hours_folder
    TEST_HOURS_FOLDER
  end

  def out
    TestOut
  end

  def debug
    false
  end
end

# Provides some helper methods.
class PunchTest < MiniTest::Test

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
    # Do nothing and move on like a baws. We don't wanna exit the test suite when
    # punch calls Kernel#exit.
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

  # Most recently created punch clock instance.
  def clock
    punch if @clock.nil?
    @clock
  end

end

MiniTest.after_run { PunchTest.clear_hours_folder }
