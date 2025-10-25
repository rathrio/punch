require_relative 'config'

class AttributesTest < Minitest::Test

  class Dog
    include Attributes
    attr_accessor :name, :age
  end

  def test_initialize_with_attributes
    dog = Dog.new(
      :name => "Fido",
      :age  => 3
    )

    assert_equal "Fido", dog.name
    assert_equal 3, dog.age
  end

end
