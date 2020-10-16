local scripted_action = require("engine/test/scripted_action")

-- integration test class
local integration_test = new_class()

-- parameters
-- name               string                         test name
-- setup              function(gameapp)              setup callback - called on test start (pure function)
-- teardown           function(gameapp)              teardown callback - called on test finish (pure function)
-- action_sequence    [scripted_action]              sequence of scripted actions - run during test
-- final_assertion    function () => (bool, string)  assertion function that returns (assertion passed, error message if failed) - called on test end
-- timeout_frames     int                            number of frames before timeout (0 for no timeout, if you know the time triggers will do the job)
-- active_gamestates  [gamestate.types]              (non-pico8 only) sequence of gamestate modules to require for that itest.
--                                                    must be the same as in itest script first line
--                                                    and true gamestate modules should be required accordingly if directly referenced
--                                                    UNUSED since gamestate_proxy has been removed, can be removed
function integration_test:init(name, active_gamestates)
  self.name = name
  self.setup = nil
  self.teardown = nil
  self.action_sequence = {}
  self.final_assertion = nil
  self.timeout_frames = 0
--#if busted
 assert(active_gamestates, "integration_test.init: non-pico8 build requires active_gamestates to define them at runtime")
 self.active_gamestates = active_gamestates
--#endif
end

--#if tostring
function integration_test:_tostring()
  return "[integration_test '"..self.name.."']"
end
--#endif

-- add an action to the action sequence. nil callback is acceptable, it acts like an empty function.
function integration_test:add_action(trigger, callback, name)
  assert(trigger ~= nil, "integration_test:add_action: passed trigger is nil")
  add(self.action_sequence, scripted_action(trigger, callback, name))
end

-- set the timeout with a time parameter in s
function integration_test:set_timeout(nb_frames)
  self.timeout_frames = nb_frames
end

-- return true if the test has timed out at given frame
function integration_test:check_timeout(frame)
  return self.timeout_frames > 0 and frame >= self.timeout_frames
end

-- return true if final assertion passes, (false, error message) else
function integration_test:check_final_assertion(app)
  if self.final_assertion then
    return self.final_assertion(app)
  else
   return true
  end
end

return integration_test
