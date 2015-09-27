require_relative 'config'

this_file = File.absolute_path(__FILE__)
Dir.glob(File.dirname(this_file) + "/*_test.rb").each do |file|
  require file unless file == this_file
end
