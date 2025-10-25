require_relative 'config'

class KernelTest < Minitest::Test
  class YesInput
    def self.gets
      'y'
    end
  end

  class NoInput
    def self.gets
      'n'
    end
  end

  class ConusedInput
    def self.gets
      'wubalubadubdub'
    end
  end

  def test_yes
    Punch.config.stub :in, YesInput do
      assert yes?('You cool?')
    end

    Punch.config.stub :in, NoInput do
      refute yes?('You cool?')
    end
  end

  def test_no
    Punch.config.stub :in, YesInput do
      refute no?('You cool?')
    end

    Punch.config.stub :in, NoInput do
      assert no?('You cool?')
    end
  end
end
