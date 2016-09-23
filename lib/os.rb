module OS
  module_function

  # http://stackoverflow.com/a/171011/1314848.
  def windows?
    !!(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ ruby_platform)
  end

  def unix?
    !windows?
  end

  def mac?
    !!(/darwin/ =~ ruby_platform)
  end

  def linux?
    unix? && !mac?
  end

  def open(str)
    system "#{open_cmd} #{str}"
  end

  def open_cmd
    case
    when mac?
      'open'
    when linux?
      'xdg-open'
    when windows?
      'START ""'
    else
      raise "Unsupported OS"
    end
  end

  def pager
    return nil if windows?
    ENV['PAGER'] || 'less'
  end

  def ruby_platform
    RUBY_PLATFORM
  end
end
