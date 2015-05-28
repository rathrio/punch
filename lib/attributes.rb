# Provides ActiveModel-like initializer.
#
# @example Initializing a class with setters it responds to
#
#   class Dog
#     include Attributes
#     attr_accessor :name, :age
#   end
#
#   dog = Dog.new :name => "foo", :age => 5
#   dog.name # => "foo"
#   dog.age  # => 5
module Attributes
  def initialize(attributes = {})
    attributes.each do |k, v|
      send("#{k}=", v) if respond_to? k
    end
  end
end
