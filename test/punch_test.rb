require_relative 'config'

current_file = File.absolute_path(__FILE__)
Dir.glob(File.dirname(current_file) + "/*_test.rb").each do |file|
  require file unless file == current_file
end