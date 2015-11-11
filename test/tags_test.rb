require_relative 'config'

class TagsTest < PunchTest
  def test_brf_parser_doesnt_ignore_tags
    brf_write <<-EOS
      Februar 2015 - Simon Kiener

      03.01.15   08:00-10:00   Total: 02:00   CRAZY

      Total: 02:00
    EOS

    punch # trigger parser

    assert_equal current_month.days.first.tags, [:crazy]
  end

  def test_tag_flag_adds_tags
    punch '--tag krank 9-1730'
    assert_punched '28.01.2015   09:00-17:30   Total: 08:30   KRANK'
  end
end
