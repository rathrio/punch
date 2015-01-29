# https://stackoverflow.com/questions/1489183/colorized-ruby-output
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green
    colorize 32
  end

  def blue
    colorize 34
  end

  def pink
    colorize 35
  end

  def yellow
    colorize 33
  end
end

class Module
  def flag(*names)
    names.each do |name|
      define_method "#{name}!" do
        instance_variable_set "@#{name}", true
      end
      define_method "#{name}?" do
        instance_variable_get "@#{name}"
      end
    end
  end
end

class Time
  def short_year
    strftime('%y').to_i
  end

  def previous_day
    self - 86400
  end

  def next_day
    self + 86400
  end
end
