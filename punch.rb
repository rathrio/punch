#!/usr/bin/ruby --disable-all
# frozen_string_literal: true

PUNCH_FILE = File.realpath(__FILE__)
$LOAD_PATH.unshift File.expand_path('../lib', PUNCH_FILE)

require 'exposable_error'
require 'os'
require 'core_extensions'
require 'option_parsing'
require 'month_year'
require 'punch'
require 'brf_parser'
require 'totals'
require 'attributes'
require 'block'
require 'day'
require 'month_names'
require 'month'
require 'block_parser'
require 'date'
require 'punch_clock'

autoload :Tempfile, 'tempfile'
autoload :FileUtils, 'fileutils'
autoload :BRFMailer, 'brf_mailer'
autoload :Stats, 'stats'
autoload :FullMonth, 'full_month'
autoload :DateParser, 'date_parser'

PunchClock.new(ARGV).punch if $PROGRAM_NAME == __FILE__
