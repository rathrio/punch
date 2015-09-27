require 'rounded_time'

module BlockPreprocessing

  # Convenience preps specific to CLI block parsing.
  #
  # This allows users to
  #
  #   * omit the colon in 4-digit blocks, e.g. "1330" instead of "13:30"
  #   * type out "now" instead of the current time
  #
  # and translates that back to normal blocks so that Block.from
  # doesn't have to deal with that stuff.
  #
  # @param arg [String] e.g. "1200-now"
  # @return [String] e.g. "12:00-17:30"
  def prepare_block_arg(arg)
    arg.gsub(/(\d{4})/) { "#{$1[0..1]}:#{$1[2..3]}" }.
      gsub(/now/) { RoundedTime.now.strftime('%H:%M') }
  end

end
