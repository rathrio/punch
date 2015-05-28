class Halfblock
  include Attributes

  def to_s
    "#{format start}-#{format finish}"
  end

  private

  def format(time)
    time.strftime "%H:%M"
  end
end
