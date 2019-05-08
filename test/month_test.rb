# frozen_string_literal: true

require_relative "config"

class MonthTest < PunchTest
  def setup
    @month = Month.from(<<-BRF, 1, 2014)
      Januar 2014

      28.11.14   18:00-19:00   Total: 01:00
      30.12.14   08:00-13:00   Total: 05:00

      Total: 21:00
    BRF
  end

  def test_sorting
    day = Day.from "02.01.15"
    day.add Block.from("14-16", day)
    @month.days << day
    @month.days.sort!

    assert_equal day, @month.days.last
  end

  def test_blocks
    assert_equal 2, @month.blocks.count
  end

  def test_name_with_title_and_username_present
    config :name => "Spongebob", :title => "Krosse Krabbe" do
      assert_equal "Krosse Krabbe - Januar 2014 - Spongebob", @month.name
    end
  end

  def test_name_with_title_missing
    config :name => "Spongebob", :title => "" do
      assert_equal "Januar 2014 - Spongebob", @month.name
    end
  end

  def test_name_with_username_missing
    config :name => "", :title => "Krosse Krabbe" do
      assert_equal "Krosse Krabbe - Januar 2014", @month.name
    end
  end

  def test_from_file
    punch '-m 1.2014 8-10'
    file_path = "#{Punch.config.hours_folder}/2014-1.txt"

    month = Month.from_file(file_path)
    assert_equal 1, month.number
    assert_equal 2014, month.year
  end

  def test_comparable
    m1 = Month.new('test month')
    m1.year = 2015
    m1.number = 2

    m2 = Month.new('test month')
    m2.year = 2015
    m2.number = 3

    assert m1 < m2

    m2.number = 1
    assert m1 > m2

    m2.number = 2
    assert m1 == m2

    m1.year = 2016
    assert m1 > m2
  end

  def test_empty
    m = Month.new('foobar')
    assert m.empty?
    refute @month.empty?
  end

  def test_short_year
    m1919 = Month.new('1919')
    m1919.year = 1919
    assert_equal 19, m1919.short_year

    m2019 = Month.new('2019')
    m2019.year = 2019
    assert_equal 19, m2019.short_year

    m3019 = Month.new('3019')
    m3019.year = 3019
    assert_equal 19, m3019.short_year
  end

  def test_stats
    assert_kind_of Stats, @month.stats
  end
end
