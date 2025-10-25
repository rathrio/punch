# frozen_string_literal: true

require_relative 'config'

class TotalsTest < Minitest::Test
  def test_fails_loudly_on_unknown_formats
    assert_raises(RuntimeError) { Totals.format(123, :some_unknown_format) }
  end
end
