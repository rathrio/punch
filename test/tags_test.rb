require_relative 'config'

class TagsTest < PunchTest

  def test_brf_parser_doesnt_ignore_tags
    brf_write <<-EOS
      Februar 2015 - Simon Kiener

      03.01.15   08:00-10:00   Total: 02:00   CRAZY

      Total: 02:00
    EOS

    assert_equal current_month.days.last.tags, [:crazy]
  end
end
