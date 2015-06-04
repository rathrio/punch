module FairRoundedTime
  def self.now
    actual_now = Time.now
    minutes = actual_now.min
    rounded_minutes = (actual_now.min * 2).round(-1) / 2
    diff = (minutes - rounded_minutes) * 60
    actual_now - diff
  end
end
