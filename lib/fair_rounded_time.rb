module FairRoundedTime
  def self.now
    actual_now = Time.now
    Time.new(
      actual_now.year,
      actual_now.month,
      actual_now.day,
      actual_now.hour,
      (actual_now.min * 2).round(-1) / 2
    )
  end
end
