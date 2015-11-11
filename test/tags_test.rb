require_relative 'config'

class TagsTest < PunchTest
  def test_parser_extracts_tags
    month = Month.from(<<-BRF, 2, 2015)
      Februar 2015 - Simon Kiener

      03.01.15   08:00-10:00   Total: 02:00   CRAZY
      04.01.15   08:00-10:00   Total: 02:00   FERIEN, FOO
      05.01.15   08:00-10:00   Total: 02:00

      Total: 02:00
    BRF

    assert_equal [:crazy], month.days[0].tags
    assert_equal [:ferien, :foo], month.days[1].tags
    assert_equal [], month.days[2].tags
  end

  def test_tag_flag_adds_tags
    punch '--tag krank 9-1730'

    assert_punched '28.01.15   09:00-17:30   Total: 08:30   KRANK'

    punch '--tag crazy'
    assert_punched '28.01.15   09:00-17:30   Total: 08:30   KRANK, CRAZY'
  end

  def test_tag_flag_doesnt_create_duplicate_tags
    punch '9-1730 --tag crazy'
    assert_punched '28.01.15   09:00-17:30   Total: 08:30   CRAZY'

    punch '--tag crazy'
    refute_punched 'CRAZY, CRAZY'
  end

  def test_clear_tags_switch_gets_rid_of_tags
    punch '--tag krank'
    assert_punched 'KRANK'

    punch '--clear-tags'
    refute_punched 'KRANK'
  end
end
