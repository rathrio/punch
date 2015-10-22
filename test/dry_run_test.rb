require_relative 'config'

class DryRunTest < PunchTest
  def test_outputs_to_stdout
    punch '--dry-run 8-10'
    assert_outputted '08:00-10:00'
  end

  def test_does_not_write_to_file
    punch '--dry-run 14-1630'
    refute_punched '14:00-16:30'
  end
end
