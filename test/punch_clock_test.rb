# frozen_string_literal: true

require_relative 'config'

class PunchClockTest < PunchTest
  def test_without_args_prints_month
    punch '8-12 13-17'
    punch
    assert_punched 'Februar'
    assert_punched '2015'
    assert_punched 'Total: 08:00'
  end

  def test_today_is_always_listed_in_output_but_not_in_brf
    punch # empty month
    date = '28.01.15'
    refute_punched date
    assert_outputted date
  end

  def test_add_one_block
    punch '18-19'
    assert_punched '28.01.15   18:00-19:00   Total: 01:00'
  end

  def test_add_multiple_blocks
    punch '9-12 12:30-17 22-23'
    assert_punched(
      '28.01.15   09:00-12:00   12:30-17:00   22:00-23:00   Total: 08:30'
    )
  end

  def test_add_block_over_midnight
    punch '23-04'
    assert_punched '28.01.15   23:00-04:00   Total: 05:00'
  end

  def test_colon_is_optional
    punch '0930-1200'
    assert_punched '28.01.15   09:30-12:00   Total: 02:30'
  end

  def test_three_digits_are_interpreted_as_hmm
    punch '930-1200'
    assert_punched '28.01.15   09:30-12:00   Total: 02:30'
  end

  def test_day_flag
    punch '-d 02.02.15 14-15:45'
    assert_punched '02.02.15   14:00-15:45   Total: 01:45'
  end

  def test_yesterday_switch
    punch '-y 11-13'
    assert_punched '27.01.15   11:00-13:00   Total: 02:00'
  end

  def test_full_switch_lists_all_days
    punch '--full'
    assert_outputted '21.01.15'
    assert_outputted '20.02.15'
  end

  def test_format_switch_normalizes_whitespace
    brf_write %{
      Februar 2015

        01.02.15 08:00-09:00  12:00-13:30                       Total: 02:30

      Total: 01:30
    }

    punch '-f'

    assert_punched '01.02.15   08:00-09:00   12:00-13:30   Total: 02:30'
  end

  def test_format_switch_recalculates_totals
    brf_write %{
      Februar 2015

      01.02.15   08:00-09:00   12:00-13:30   Total: 22:00

      Total: 00:00
    }

    punch '-f'

    assert_punched '01.02.15   08:00-09:00   12:00-13:30   Total: 02:30'
  end

  def test_format_gets_rid_of_empty_days
    brf_write %{
      Februar 2015 - Rathesan Iyadurai

      22.01.15   15:00-15:30                 Total: 00:30
      24.01.15
      25.01.15   13:00-13:15   16:20-17:00   Total: 00:55

      Total: 01:25
    }

    punch '-f'

    refute_includes brf_content, '24.03.15'
  end

  def test_format_gets_rid_of_ongoing_blocks_if_enabled
    brf_write %{
      Februar 2015 - Rathesan Iyadurai

      25.01.15   00:00-00:00   16:20-17:00   Total: 00:40

      Total: 00:40
    }

    punch '-f'
    assert_includes brf_content, '00:00-00:00'

    config :remove_ongoing_blocks_on_format => true do
      punch '-f'
      refute_includes brf_content, '00:00-00:00'
    end
  end

  def test_format_gets_rid_of_days_with_ongoing_blocks_if_enabled
    brf_write %{
      Februar 2015 - Rathesan Iyadurai

      03.01.15   00:00-00:00                 Total: 00:00

      Total: 00:00
    }

    config :remove_ongoing_blocks_on_format => true do
      punch '-f'
    end

    refute_includes brf_content, '03.01.15'
  end

  def test_format_keeps_emtpy_days_with_comments
    brf_write %{
      Februar 2015 - Rathesan Iyadurai

      03.01.15   00:00-00:00                 Total: 00:00   Some comment

      Total: 00:00
    }

    punch '-f'

    assert_includes brf_content, '03.01.15'
  end

  def test_punch_previous_month_with_previous_switch
    punch "-p 2-3"

    assert_punched "Januar 2015"
  end

  def test_punch_next_month_with_next_switch
    punch "-n 2-3"

    assert_punched "März 2015"
  end

  def test_option_order_shouldnt_matter
    punch '-p -d 02.04.15 8-12'

    assert_punched "Januar 2015"
    assert_punched "02.04.15   08:00-12:00   Total: 04:00"
  end

  def test_option_order_shouldnt_matter2
    punch '-d 02.04.15 -p 8-12'

    assert_punched "Januar 2015"
    assert_punched "02.04.15   08:00-12:00   Total: 04:00"
  end

  def test_option_order_shouldnt_matter3
    punch '-d 02.04.15 8-12 -p'

    assert_punched "Januar 2015"
    assert_punched "02.04.15   08:00-12:00   Total: 04:00"
  end

  def test_option_order_shouldnt_matter4
    punch '8-12 -p -d 02.04.15'

    assert_punched "Januar 2015"
    assert_punched "02.04.15   08:00-12:00   Total: 04:00"
  end

  def test_punching_at_the_end_of_the_year_doesnt_fail
    Timecop.freeze(2015, 11, 22) do
      punch
      assert_equal 12, current_month.number
    end
  end

  def test_options_switch
    punch '--options'

    PunchClock::OPTIONS.each do |option|
      assert_outputted option
    end
  end

  def test_cards_switch
    punch '--cards'
    assert_outputted 'test' # The only card configured in test/.punchrc.rb
  end

  def test_cards
    config :cards => { :foo => { :title => 'Foo' } } do
      punch 'foo'
      assert_outputted 'Foo'

      punch 'bar'
      assert_outputted %{The card "bar" doesn't exist}

      punch 'foo bar'
      assert_outputted %{The card "bar" doesn't exist}
    end
  end

  def test_version
    refute_empty clock.version
  end

  def test_last_release
    refute_empty clock.last_release
  end

  def test_all_punchrc_options_have_name_and_description
    refute_empty Punch.options

    Punch.options.each do |option|
      assert_kind_of Symbol, option.name
      assert_kind_of String, option.description
      refute_empty option.description
    end
  end

  def test_help_file
    assert_match(/help.txt$/, clock.help_file)
  end

  def test_test_file
    assert_match(/punch_test.rb$/, clock.test_file)
  end
end
