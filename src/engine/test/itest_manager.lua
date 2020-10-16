local input = require("engine/input/input")
local integration_test = require("engine/test/integration_test")
local itest_run = require("engine/test/itest_run")
local test_states = itest_run.test_states
local time_trigger = require("engine/test/time_trigger")

-- integration test manager singleton: registers all itests
-- itests         {string: itest}  registered itests, indexed by name
-- itest_run            itest_run  unique instance of itest_run (component)
-- current_itest_index  int        index of current itest (0 if no itest running)
local itest_manager = singleton(function (self)
  self.itests = {}
  self.itest_run = itest_run(self)
  self.current_itest_index = 0
end)

-- all-in-one utility function that creates and register a new itest,
-- defining setup, actions and final assertion inside a contextual callback,
-- as in the describe-it pattern
-- name        string        itest name
-- states      {gamestates}  sequence of non-dummy gamestates used for the itest
-- definition  function      definition callback

-- definition example:
--   function ()
--     setup_callback(function (app)
--       -- setup test
--     end)
--     teardown_callback(function (app)
--       -- tear test down
--     end)
--     add_action(time_trigger(1.0, false, 30), function ()
--       -- change character intention
--     end)
--     add_action(time_trigger(0.5, false, 30), function ()
--       -- more actions
--     end)
--     final_assert(function (app)
--       return -- true if everything is as expected
--     end)
--   end)
function itest_manager:register_itest(name, states, definition)
  local itest = integration_test(name, states)
  self:register(itest)

  -- context
  -- last time trigger
  local last_time_trigger = nil

  -- we are defining global functions capturing local variables, which is bad
  --  but it's acceptable to have them accessible inside the definition callback
  --  (as getfenv/setfenv cannot be implemented in pico8 due to missing debug.getupvalue)
  -- actually they would be callable even after calling register_itest as they "leak"
  -- so either use a dsl as in pico-sonic, or coroutines to yield wait

  -- don't name setup, busted would hide this name
  -- callback: function(gameapp)    setup callback, app is passed to provide access to other objects
  function setup_callback(callback)
    itest.setup = callback
  end

  -- don't name teardown, busted would hide this name
  -- callback: function(gameapp)    teardown callback, app is passed to provide access to other objects
  function teardown_callback(callback)
    itest.teardown = callback
  end

  function add_action(trigger, callback, name)
    itest:add_action(trigger, callback, name)
  end

  function wait(time, use_frame_unit)
    if last_time_trigger then
      -- we were already waiting, so finish last wait with empty action
      itest:add_action(last_time_trigger, nil)
    end
    -- get fps from app via itest_run
    last_time_trigger = time_trigger(time, use_frame_unit, itest_manager.itest_run.app.fps)
  end

  function act(callback)
    if last_time_trigger then
      itest:add_action(last_time_trigger, callback)
      last_time_trigger = nil  -- consume so we know no final wait-action is needed
    else
      -- no wait since last action (or this is the first action), so use immediate trigger
      itest:add_action(time_trigger.immediate(), callback)
    end
  end

  -- callback: function(gameapp) -> (bool, str)    assert callback, app is passed to provide access to other objects
  --                                               bool is true iff test succeeded, str is failure message if bool is false
  function final_assert(callback)
    itest.final_assertion = callback
  end

  -- macro helper: press input for 1 frame, then release and wait 1 frame
  function short_press(button_id)
    act(function ()
      input.simulated_buttons_down[0][button_id] = true
    end)
    wait(1, true)
    act(function ()
      input.simulated_buttons_down[0][button_id] = false
    end)
    wait(1, true)
  end

  definition()

  -- if we finished with a wait (with or without final assertion),
  --  we need to close the itest with a wait-action
  if last_time_trigger then
    itest:add_action(last_time_trigger, nil)
  end
end

-- register a created itest instance
-- you can add actions and final assertion later
function itest_manager:register(itest)
  add(self.itests, itest)
end

-- proxy method for itest runner helper method
function itest_manager:init_game_and_start_by_index(index)
  if #self.itests == 0 then
    -- no itests registered, return to avoid crash
    return
  end

  local itest = self.itests[index]
  assert(itest, "itest_manager:init_game_and_start_by_index: index is "..tostr(index).." but only "..tostr(#self.itests).." were registered.")
  self.current_itest_index = index
  self.itest_run:init_game_and_start(itest)
end

function itest_manager:init_game_and_start_itest_by_relative_index(delta)
  if #self.itests == 0 then
    -- no itests registered, return to avoid crash
    return
  end

  -- clamp new index
  local new_index = mid(1, self.current_itest_index + delta, #self.itests)
  -- check that an effective index change occurs (may not happen due to clamping)
  if new_index ~= self.current_itest_index then
    -- cleanup any previous running itest (this will clear the current test index)
    if self.itest_run.current_test then
      self.itest_run:stop_and_reset_game()
    end
    -- start the new test (this will set the current test index)
    self:init_game_and_start_by_index(new_index)
  end
end

function itest_manager:init_game_and_restart_itest()
  -- cleanup and restart current itest if any
  -- since the index doesn't need to be changed, don't use an by-index method
  --  and call init_game_and_start
  if self.itest_run.current_test then
    -- store index before stop clears it
    local itest_index = itest_manager.current_itest_index
    self.itest_run:stop_and_reset_game()
    itest_manager:init_game_and_start_by_index(itest_index)
  end
end

function itest_manager:init_game_and_start_next_itest()
  self:init_game_and_start_itest_by_relative_index(1)
end

function itest_manager:handle_input()
  -- avoid crash when itest sequence is empty
  if #self.itests == 0 then
    return
  end

  -- press arrow keys to navigate freely in itests, even if not finished
  -- press O to restart current itest, X to toggle pause

  -- since input.mode is simulated during itests, use pico8 api directly for input

  if self.itest_run.current_state ~= test_states.paused then
    if btnp(button_ids.left) then
      -- go back to previous itest
      self:init_game_and_start_itest_by_relative_index(-1)
    elseif btnp(button_ids.right) then
      -- skip current itest
      self:init_game_and_start_next_itest()
    elseif btnp(button_ids.up) then
      -- go back 10 itests
      self:init_game_and_start_itest_by_relative_index(-10)
    elseif btnp(button_ids.down) then
      -- skip many itests
      self:init_game_and_start_itest_by_relative_index(10)
    elseif btnp(button_ids.o) then
      self:init_game_and_restart_itest()
    elseif btnp(button_ids.x) then
      self.itest_run:toggle_pause()
    end
  else
    -- it's difficult to go back in time (but possible by going back to 0 and readvancing in time)
    -- for now only allow single-step or multi-step forward
    if btnp(button_ids.right) then
      -- advance step
      self.itest_run:step_game_and_test()
    elseif btnp(button_ids.down) then
      -- skip 10 steps
      for i = 1, 10 do
        self.itest_run:step_game_and_test()
      end
    elseif btnp(button_ids.o) then
      self:init_game_and_restart_itest()
    elseif btnp(button_ids.x) then
      self.itest_run:toggle_pause()
    end
  end

end

function itest_manager:update()
  self.itest_run:update_game_and_test()
end

function itest_manager:stop_and_reset_game()
  self.itest_run:stop_and_reset_game()
end

function itest_manager:draw()
  self.itest_run:draw_game()
  self:draw_test_info()
end

function itest_manager:draw_test_info()
  if self.itest_run.current_test then
    api.print("#"..self.current_itest_index.." "..self.itest_run.current_test.name, 2, 2, colors.yellow)
    api.print(self.itest_run.current_state, 2, 9, self:get_test_state_color(self.itest_run.current_state))
  else
    if #self.itests > 0 then
      api.print("no itest running", 8, 8, colors.white)
    else
      api.print("no itests found", 8, 8, colors.white)
    end
  end
end

function itest_manager.get_test_state_color(test_state)
  if test_state == test_states.none then
    return colors.white
  elseif test_state == test_states.running then
    return colors.white
  elseif test_state == test_states.paused then
    return colors.orange
  elseif test_state == test_states.success then
    return colors.green
  elseif test_state == test_states.failure then
    return colors.red
  else  -- test_state == test_states.timeout then
    return colors.dark_purple
  end
end

return itest_manager
