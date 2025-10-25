require_relative 'config'

class BlockParserTest < Minitest::Test
  def setup
    Timecop.freeze Time.new(2015, 10, 8, 14)
    @day = Day.new
    @day.set Time.now
  end

  def teardown
    Timecop.return
  end

  def test_sets_day
    block = BlockParser.parse '08:15-12:00', @day
    assert_equal @day, block.day
  end

  def test_parse_regular_block
    block = BlockParser.parse '08:15-12:00', @day
    assert_equal '08:15-12:00', block.to_s
  end

  def test_parse_shorthands
    block = BlockParser.parse '8:15-12', @day
    assert_equal '08:15-12:00', block.to_s
  end

  def test_parse_colonless
    block = BlockParser.parse '0815-1200', @day
    assert_equal '08:15-12:00', block.to_s
  end

  def test_parse_three_digits
    block = BlockParser.parse '815-900', @day
    assert_equal '08:15-09:00', block.to_s
  end

  def test_parse_now
    block = BlockParser.parse '8:15-now', @day
    assert_equal '08:15-14:00', block.to_s
  end

  def test_parse_start_ongoing
    block = BlockParser.parse '8:15', @day
    assert_equal '08:15-08:15', block.to_s
  end

  def test_parse_complete_ongoing_with_now
    @day.add Block.from('11:00-11:00', @day)
    block = BlockParser.parse 'now', @day
    assert_equal '11:00-14:00', block.to_s
  end

  def test_parse_complete_ongoing_with_shorthands
    @day.add Block.from('11:00-11:00', @day)
    block = BlockParser.parse '14', @day
    assert_equal '11:00-14:00', block.to_s
  end

  def test_error_handling
    [
      '',
      '98-99',
      '-12',
      'foobar',
      '9000'
    ].each do |invalid_block|
      assert_raises(BlockParser::ParserError) do
        BlockParser.parse(invalid_block, @day)
      end
    end
  end
end
