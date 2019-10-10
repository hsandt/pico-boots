local flow = require("engine/application/flow")
local coroutine_runner = require("engine/application/coroutine_runner")
local class = require("engine/core/class")
local input = require("engine/input/input")

-- main class for the game, taking care of the overall init, update, render
-- usage: derive from gameapp and override:
--   instantiate_gamestates, on_start, on_reset, on_update, on_render
-- in the main _init, set the initial_gamestate and call the app start()
-- in the main _update(60), call the app update()
-- in the main _draw, call the app render()
-- in integration tests, call the app reset() before starting a new itest
local gameapp = new_class()

-- components
--   managers           manager                  table of managers to update and render in the loop,
--                                                 indexed by manager type
--   coroutine_runner   coroutine_runner         handles coroutine curries start, update and stop
-- parameters
--   fps                int                      target fps (fps30 or fps60). set them in derived app
--                                                 when calling base constructor
--   delta_time         float                    derived from fps, time per frame in seconds
--   initial_gamestate  string|nil               key of the initial first gamestate to enter (nil if unset)
--                                               set it manually before calling start(),
--                                                 and make sure you called register_gamestates with a matching state
function gameapp:_init(fps)
  self.managers = {}
  self.coroutine_runner = coroutine_runner()

  self.fps = fps
  self.delta_time = 1 / fps
  self.initial_gamestate = nil
end

-- Register the managers you want to update and render
--
-- They may be managers provided by the engine or custom managers.
-- In this engine, we prefer injection to having a configuration with many flags
--   to enable/disable certain managers.
-- We can still override on_update/on_render for custom effects,
--   but prefer handling managers when possible
-- Call this in your derived gameapp with all the managers you need during the game.
-- You can then access the manager from any gamestate with self.app.managers[':type']
function gameapp:register_managers(...)
  for manager in all({...}) do
    self.managers[manager.type] = manager
  end
end

-- return a sequence of newly instantiated gamestates
-- this is preferred to passing gamestate references directly
--   to avoid two apps sharing the same gamestates
-- you must override this in order to have your gamestates registered on start
function gameapp:instantiate_gamestates()
  -- override ex:
  -- inject app itself in gamestates, to allow access to app at any time
  --  without needing a singleton
  -- return {my_gamestate1(self), my_gamestate2(self), my_gamestate3(self)}
  return {}
end

-- register
function gameapp:register_gamestates()
  for state in all(self:instantiate_gamestates()) do
    flow:add_gamestate(state)
  end
end

-- unlike _init, init_modules is called later, after finishing the configuration
-- in pico-8, it must be called in the global _init function
function gameapp:start()
  self:on_pre_start()

  self:register_gamestates()

  -- REFACTOR: consider making flow a very generic manager, that knows the initial gamestate
  -- and is only added if you want (but mind the start/update/render order)
  assert(self.initial_gamestate ~= nil, "gameapp:start: gameapp.initial_gamestate is not set")
  flow:query_gamestate_type(self.initial_gamestate)
  for _, manager in pairs(self.managers) do
    manager:start()
  end

  self:on_post_start()
end

-- override to initialize custom managers
function gameapp:on_pre_start() -- virtual
end

-- override to initialize custom managers
function gameapp:on_post_start() -- virtual
end

--#if itest
function gameapp:reset()
  flow:init()

  self:on_reset()
end

-- override to call :init on your custom managers, or to reset anything set up in
-- in gameapp:start/on_start, really
function gameapp:on_reset() -- virtual
end
--#endif

function gameapp:update()
  input:process_players_inputs()

  self.coroutine_runner:update_coroutines()

  for _, manager in pairs(self.managers) do
    if manager.active then
      manager:update()
    end
  end

  flow:update()

  self:on_update()
end

-- override to add custom update behavior
function gameapp:on_update() -- virtual
end

function gameapp:draw()
  cls()

  flow:render()

  -- managers tend to draw stuff on top of the rest, so render after flow (i.e. gamestate)
  for _, manager in pairs(self.managers) do
    if manager.active then
      manager:render()
    end
  end

  self:on_render()
end

-- override to add custom render behavior
function gameapp:on_render() -- virtual
end

-- coroutine helpers

-- create and register coroutine with optional arguments
-- ! for methods, remember to pass the instance it*self* as first optional argument !
function gameapp:start_coroutine(async_function, ...)
  self.coroutine_runner:start_coroutine(async_function, ...)
end

function gameapp:stop_all_coroutines()
  self.coroutine_runner:stop_all_coroutines()
end

-- yield_delay variant taking time in seconds
function gameapp:yield_delay_s(delay_s)
  -- the delay in frames may be fractional, and we want to wait for the last frame
  --   to be fully completed, so ceil
  yield_delay(ceil(delay_s * self.fps))
end

return gameapp
