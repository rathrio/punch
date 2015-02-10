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
end

# Test helper methods

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
end

# Delete all BRF files in test hours folder.
def clear_hours_folder
  system "rm #{hours_folder}/*" unless `ls #{hours_folder}`.empty?
end

# Recent test output.
def output
  TestOut.output
end

# Content of current BRF file.
def brf_content
  `cat #{@clock.brf_filepath}`
end

MiniTest.after_run { clear_hours_folder }
