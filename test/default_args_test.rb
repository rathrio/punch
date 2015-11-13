require_relative 'config'

class DefaultArgsTest < PunchTest
  def test_punch_loads_default_args
    refute_punched '27.01.15'

    config :default_args => '-y' do
      punch '8-9'
      assert_punched '27.01.15   08:00-09:00'
    end
  end
end
