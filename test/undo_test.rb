# require_relative 'config'

# class UndoTest < PunchTest
#   def setup
#     super
#     punch '8-10'
#   end

#   def test_undo_regular_punch
#     punch '12-14'
#     assert_punched '28.01.15   08:00-10:00   12:00-14:00   Total: 04:00'

#     punch '--undo'
#     assert_punched '28.01.15   08:00-10:00   Total: 02:00'
#   end

#   def test_undo_start_ongoing
#     punch '13'
#     assert_punched '28.01.15   08:00-10:00   13:00-13:00   Total: 02:00'

#     punch '--undo'
#     assert_punched '28.01.15   08:00-10:00   Total: 02:00'
#   end

#   def test_undo_complete_ongoing
#     punch '13'
#     punch '14'
#     assert_punched '28.01.15   08:00-10:00   13:00-14:00   Total: 03:00'

#     punch '--undo'
#     assert_punched '28.01.15   08:00-10:00   13:00-13:00   Total: 02:00'
#   end

#   def test_undo_now
#     punch '13-now'
#     assert_punched '28.01.15   08:00-10:00   13:00-14:00   Total: 03:00'

#     punch '--undo'
#     assert_punched '28.01.15   08:00-10:00   Total: 02:00'
#   end
# end
