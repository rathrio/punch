class ModuleTest < MiniTest::Test
  class Dog
    flag :hungry, :old
  end

  def setup
    @dog = Dog.new
  end

  def test_flag_generates_predicate_methods
    assert_respond_to @dog, :hungry?
    assert_respond_to @dog, :old?
  end

  def test_flags_return_false_by_defaulft
    refute @dog.hungry?
    refute @dog.old?
  end

  def test_flag_generates_bang_methods
    assert_respond_to @dog, :hungry!
    assert_respond_to @dog, :old!
  end

  def test_bang_methods_set_flags_to_true
    @dog.hungry!
    assert @dog.hungry?
    refute @dog.old?
  end
end
