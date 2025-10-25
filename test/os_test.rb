require_relative 'config'

class OSTest < Minitest::Test
  def test_windows_when_ruby_platform_windows
    %w(cygwin mswin mingw bccwin wince emx).each do |s|
      OS.stub :ruby_platform, s do
        assert OS.windows?
        refute OS.mac?
        refute OS.linux?
      end
    end
  end

  def test_mac_when_ruby_platform_darwin
    OS.stub :ruby_platform, 'x86_64-darwin15foobar' do
      assert OS.mac?
      refute OS.linux?
      refute OS.windows?
    end
  end

  def test_unix_when_not_windows
    %w(foobar x86_64-linux x86_64-darwin).each do |s|
      OS.stub :ruby_platform, s do
        assert OS.unix?
        refute OS.windows?
      end
    end
  end

  def test_linux_when_not_windows_and_not_mac
    %w(foobar x86_64-linux blabla).each do |s|
      OS.stub :ruby_platform, s do
        assert OS.linux?
        refute OS.mac?
        refute OS.windows?
      end
    end
  end

  def test_open_cmd_returns_open_on_mac
    OS.stub :ruby_platform, 'x86_64-darwin' do
      assert_equal 'open', OS.open_cmd
    end
  end

  def test_open_cmd_returns_xdg_open_on_linux
    OS.stub :ruby_platform, 'x86_64-linux' do
      assert_equal 'xdg-open', OS.open_cmd
    end
  end

  def test_open_cmd_returns_start_on_windows
    %w(cygwin mswin mingw bccwin wince emx).each do |s|
      OS.stub :ruby_platform, s do
        assert_equal 'START ""', OS.open_cmd
      end
    end
  end

  def test_pager_is_nil_on_windows
    %w(cygwin mswin mingw bccwin wince emx).each do |s|
      OS.stub :ruby_platform, s do
        assert_nil OS.pager
      end
    end
  end

  def test_pager_is_less_on_unix
    ENV['PAGER'] = nil
    %w(linux darwin).each do |s|
      OS.stub :ruby_platform, s do
        assert_equal 'less', OS.pager
      end
    end
  end
end
