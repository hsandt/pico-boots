local input = require("engine/input/input")

-- integration test run
-- in general there should be only one running
-- unlike integration_test it's not pure data on the itest, it has a state
--  that tracks where we are in the itest, and refers to an actual integration_test
-- usage:
-- first, make sure you have registered itests via the itest_manager
--   and that you are running an itest via itest_manager:init_game_and_start_by_index (a proxy for itest_run:init_game_and_start)
-- in init, create a game app, set its initial_gamestate and set itest_run.app to this app instance
-- in _update(60), call itest_run:update_game_and_test
-- in _draw, call itest_run:draw_game_and_test

-- attributes
-- initialized          bool              true if it has already been initialized.
--                                        initialization is lazy and is only needed once
-- current_test         integration_test  current itest being run
-- current_frame        int               index of the current frame run
-- last_trigger_frame   int               stored index of the frame where the last command trigger was received
-- next_action_index    int               index of the next action to execute in the action list
-- current_state        test_states       stores if test has not started, is still running or has succeeded/failed
-- current_message      string            failure message, nil if test has not failed
-- app                  gameapp           gameapp instance of the tested game
--                                        must be set directly with itest_run.app = ...
-- manager              itest_manager     reference to directing itest manager

-- a test's lifetime follows the phases:
-- none -> running -> success/failure/timeout (still alive, but not updated)
--  -> stopped when a another test starts running
local itest_run = new_class()

local test_states = {
  none = 'none',          -- no test started
  running = 'running',    -- the test is still running
  paused  = 'paused',     -- the test is paused, not finished yet
  success = 'success',    -- the test has just succeeded
  failure = 'failure',    -- the test has just failed
  timeout = 'timeout'     -- the test has timed out
}
itest_run.test_states = test_states

function itest_run:init(manager)
  self.initialized = false
  -- self.current_test = nil
  self.current_frame = 0
  self.last_trigger_frame = 0
  self.next_action_index = 1
  self.current_state = test_states.none
  -- self.current_message = nil
  -- self.app = nil
  self.manager = manager
end

-- helper method to use in rendered itest init
function itest_run:init_game_and_start(test)
  assert(self.app ~= nil, "itest_run:init_game_and_start: self.app is not set")

  -- make sure to call stop_and_reset_game before starting the next test
  -- either via busted teardown (in headless) or manually (in PICO-8)
  assert(self.current_test == nil, "itest_run:init_game_and_start: test is still running")

  self.app:start()
  self:start(test)
end

-- helper method to use in rendered itest init
function itest_run:stop_and_reset_game()
  assert(self.app ~= nil, "itest_run:stop_and_reset_game: self.app is not set")

  -- reset itest runner and app in reverse order of start
  self:stop()
  self.app:reset()
end

-- helper method to use in rendered itest _update(60)
function itest_run:update_game_and_test()
  if self.current_state == test_states.running then
    self:step_game_and_test()
  end
end

-- advance simulation by 1 frame
function itest_run:step_game_and_test()
  -- update app, then test runner
  -- updating test runner 2nd allows us to check the actual game state at final frame f,
  --  after everything has been computed
  -- time_trigger(0, true)  initial actions will still be applied before first frame
  --  thanks to the initial check_next_action on start, but setup is still recommended
  log("frame #"..self.current_frame + 1, "frame")
  self.app:update()
  self:update()
  if self.current_state ~= test_states.running then
    log("itest '"..self.current_test.name.."' ended with "..self.current_state.."\n", 'itest')
    if self.current_state == test_states.failure then
      log("failed: "..self.current_message.."\n", 'itest')
    end
  end
end

-- helper method to use in rendered itest _draw
function itest_run:draw_game()
  self.app:draw()
end

-- start a test: integration_test
function itest_run:start(test)
  -- lazy initialization
  if not self.initialized then
    self:initialize()
  end

  -- use simulated input during itests
  -- (not inside initialize as gameapp:reset also resets input so we must reenable simulation)
  input.mode = input_modes.simulated

  -- log after initialize which sets up the logger
  log("starting itest: '"..test.name.."'", 'itest')

  self.current_test = test
  self.current_state = test_states.running

  if test.setup then
    test.setup(self.app)
  end

  -- edge case: 0 actions in the action sequence. check end
  -- immediately to avoid out of bounds index in check_next_action
  if not self:check_end() then
    self:check_next_action()
  end
end

function itest_run:update()
  assert(self.current_test, "itest_run:update: current_test is not set")
  if self.current_state ~= test_states.running then
    -- the current test is over and we already got the result
    -- do nothing and fail silently (to avoid crashing
    -- just because we repeated update a bit too much in utests)
    return
  end

  -- advance time
  self.current_frame = self.current_frame + 1

  -- check for timeout (if not 0)
  if self.current_test:check_timeout(self.current_frame) then
    self.current_state = test_states.timeout
  else
    self:check_next_action()
  end
end

function itest_run:toggle_pause()
  -- toggle pause if running or paused (do nothing if already finished)
  if self.current_state == test_states.running then
    self.current_state = test_states.paused
  elseif self.current_state == test_states.paused then
    self.current_state = test_states.running
  end
end

function itest_run:initialize()
  self.initialized = true
end

function itest_run:check_next_action()
  assert(self.next_action_index <= #self.current_test.action_sequence, "self.next_action_index ("..self.next_action_index..") is out of bounds for self.current_test.action_sequence (size "..#self.current_test.action_sequence..")")

  -- test: chain actions with no intervals between them
  local should_trigger_next_action
  repeat
  -- check if next action should be applied
  local next_action = self.current_test.action_sequence[self.next_action_index]
  local should_trigger_next_action = next_action.trigger:check(self.current_frame - self.last_trigger_frame)
  if should_trigger_next_action then
    -- apply next action and update time/index, unless nil (useful to just wait before itest end and final assertion)
    if next_action.callback then
      next_action.callback()
    end
    self.last_trigger_frame = self.current_frame
    self.next_action_index = self.next_action_index + 1
      if self:check_end() then
        break
      end
  end
  until not should_trigger_next_action
end

function itest_run:check_end()
  -- check if last action was applied, end now
  -- this means you can define an 'end' action just by adding an empty action at the end
  if self.current_test.action_sequence[1] then
  end
  if self.next_action_index > #self.current_test.action_sequence then
    self:end_with_final_assertion()
    return true
  end
  return false
end

function itest_run:end_with_final_assertion()
  -- check the final assertion so we know if we should end with success or failure
  result, message = self.current_test:check_final_assertion(self.app)
  if result then
    self.current_state = test_states.success
  else
    self.current_state = test_states.failure
    self.current_message = message
  end
end

-- stop the current test, tear it down and reset all values
-- this is only called when starting a new test, not when it finished,
--  so we can still access info on the current test while the user examines its result
function itest_run:stop()
  -- in headless itests utest, it is possible to have no current test when stopping,
  --   e.g. in init_game_and_start, self.app:start() failed with error
  --   so itest_run:start(test) was never called, but after_each() is trying to clean up
  if self.current_test then
    if self.current_test.teardown then
      self.current_test.teardown(self.app)
    end
  end

  self.manager.current_itest_index = 0
  self.current_test = nil
  self.current_frame = 0
  self.last_trigger_frame = 0
  self.next_action_index = 1
  self.current_state = test_states.none
end

return itest_run
