class RoundedTime

  def self.now
    new(Time.now).time
  end

  def initialize(time)
    @time = time
  end

  def time
    send Punch.config.punch_now_rounder
  rescue NoMethodError
    fair
  end

  private

  def fair
    minutes = @time.min
    rounded_minutes = (@time.min * 2).round(-1) / 2
    diff = (minutes - rounded_minutes) * 60
    @time -= diff
  end

  def greedy
  end

  def exact
    @time
  end

end
