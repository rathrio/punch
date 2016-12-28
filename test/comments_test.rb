require_relative 'config'

class CommentsTest < PunchTest
  def test_parser_extracts_comments
    month = Month.from(<<-BRF, 2, 2015)
      Februar 2015 - Simon Kiener

      03.01.15   08:00-10:00   Total: 02:00   2crazy
      04.01.15   08:00-10:00   Total: 02:00   FERIEN, FOObar;;
      05.01.15   08:00-10:00   Total: 02:00

      Total: 02:00
    BRF

    assert_equal '2crazy', month.days[0].comment
    assert_equal 'FERIEN, FOObar;;', month.days[1].comment
    assert_nil month.days[2].comment
  end

  def test_comment_flag_adds_comment
    punch '--comment krank 9-1730'
    assert_punched '28.01.15   09:00-17:30   Total: 08:30   krank'

    punch '--comment crazy'
    assert_punched '28.01.15   09:00-17:30   Total: 08:30   crazy'
  end

  def test_clear_comment_flag_clears_comment
    punch '--comment 22fooba.riUs'
    assert_punched '22fooba.riUs'

    punch '--clear-comment'
    refute_punched '22fooba.riUs'
  end

  # Comments replaces the tags feature. Make sure that the tag flag and
  # switches still work for familiarity.
  def test_tags_compatibility
    punch '--tag 4hello_ 10-12'
    assert_punched '28.01.15   10:00-12:00   Total: 02:00   4hello_'

    punch '--clear-tags'
    refute_punched '4hello_'
  end
end
