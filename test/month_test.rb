require_relative 'config'

class MonthTest < PunchTest
  def setup
    @month = Month.from(<<-EOS, 1, 2014)
      Januar 2014

      28.11.14   18:00-19:00   Total: 01:00
      30.12.14   08:00-13:00   Total: 05:00

      Total: 21:00
    EOS
  end

  def test_sorting
    day = Day.from "02.01.15"
    day.add Block.from("14-16", day)
    @month.days << day
    @month.days.sort!

    assert_equal day, @month.days.last
  end

  def test_name_with_title_and_username_present
    config :name => 'Spongebob', :title => 'Krosse Krabbe' do
      assert_equal 'Krosse Krabbe - Januar 2014 - Spongebob', @month.name
    end
  end

  def test_name_with_title_missing
    config :name => 'Spongebob', :title => '' do
      assert_equal 'Januar 2014 - Spongebob', @month.name
    end
  end

  def test_name_with_username_missing
    config :name => '', :title => 'Krosse Krabbe' do
      assert_equal 'Krosse Krabbe - Januar 2014', @month.name
    end
  end
end
