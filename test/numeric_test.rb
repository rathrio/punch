require_relative 'config'

class NumericTest < Minitest::Test
  def test_left_pad
    assert_equal '03', 3.left_pad
    assert_equal '3.0', 3.0.left_pad
    assert_equal '03.0', 3.0.left_pad(:length => 4)
    assert_equal ' 3.2', 3.2.left_pad(:length => 4, :with => ' ')
  end
end
