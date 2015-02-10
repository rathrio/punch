require 'minitest/autorun'
require 'minitest/pride'
require 'timecop'

require_relative '../punch'

TEST_CONFIG_FILE  = File.expand_path('.punchrc', File.dirname(__FILE__))
TEST_HOURS_FOLDER = File.expand_path('hours', File.dirname(__FILE__))


module TestOut
  class << self
    def puts(*); end
  end
end

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
def punch(args)
  PunchClock.new(args.split).punch
end

# Delete all BRF files in test hours folder.
def clear_hours_folder
  system "rm #{TEST_HOURS_FOLDER}/*" unless `ls #{TEST_HOURS_FOLDER}`.empty?
end

MiniTest.after_run { clear_hours_folder }

require_relative 'day_test'
require_relative 'month_test'
require_relative 'punch_clock_test'
