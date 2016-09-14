task :default => :test

desc 'Link punch.rb to /usr/local/bin'
task :install do
  if system "ln -sr punch.rb /usr/local/bin/punch"
    puts 'punch.rb sucessfully linked to /usr/local/bin/punch. ' \
      'Try executing "punch".'
  end
end

desc 'Remove punch.rb link from /usr/local/bin'
task :uninstall do
  if system "rm $(find -L /usr/local/bin -samefile punch.rb)"
    puts "punch.rb sucessfully unlinked from /usr/local/bin."
  end
end

desc 'Run test suite'
task :test do
  require_relative 'test/punch_test'
end

desc 'Start a pry session with punch loaded'
task :console do
  # Super unoptimized way to reload all punch ruby files.
  def reload!
    warn = $VERBOSE
    $VERBOSE = nil
    load 'punch.rb'
    Dir['lib/*.rb'].each { |f| load f }
    $VERBOSE = warn
    true
  end

  reload!
  require 'pry'
  Pry.start
end

desc 'Start a pry session with the current month loaded'
task :debug_month do
  require 'pry'
  require_relative 'punch'

  PunchClock.new(%w(--console)).punch
end
