require_relative 'config'

class StringTest < Minitest::Test
  def test_abolute_path_returns_abolute_file_path
    Dir.stub :home, '/Users/spongebob' do
      assert_equal 'foobar', 'foobar'.absolute_path
      assert_equal '/Users/spongebob/foo/bar/punch',
        '/Users/spongebob/foo/bar/punch'.absolute_path
      assert_equal '/Users/spongebob/foo/bar/punch',
        '~/foo/bar/punch'.absolute_path
    end
  end
end
