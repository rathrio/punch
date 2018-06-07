# frozen_string_literal: true

# Provides utility functions for determining OS and OS-specific system calls.
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
    if mac?
      'open'
    elsif linux?
      'xdg-open'
    elsif windows?
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
