local flow = require("engine/application/flow")
local coroutine_runner = require("engine/application/coroutine_runner")
local input = require("engine/input/input")

-- main class for the game, taking care of the overall init, update, render
-- usage: derive from gameapp and override:
--   instantiate_gamestates, on_start, on_reset, on_update, on_render
-- in the main init, set the initial_gamestate and call the app start()
-- in the main _update(60), call the app update()
-- in the main _draw, call the app render()
-- in integration tests, call the app reset() before starting a new itest
local gameapp = new_class()

-- components
--   managers (#manager) manager                  table of managers to update and render in the loop,
--                                                 indexed by manager type
--   coroutine_runner    coroutine_runner         handles coroutine curries start, update and stop
-- parameters
--   fps                 int                      target fps (fps30 or fps60). set them in derived app
--                                                 when calling base constructor
--   delta_time          float                    derived from fps, time per frame in seconds
--   initial_gamestate   string|nil               key of the initial first gamestate to enter (nil if unset)
--                                               set it manually before calling start(),
--                                                 and make sure you called register_gamestates with a matching state
--  debug_paused (#debug_menu)       bool        true when the app is paused. Currently used for debug step only.
--  debug_spritesheet (#debug_menu)  bool        true when we should show the spritesheet on-screen.
--                                                 Useful when reloading sprites at runtime as they cannot be inspected
--                                                 in the editor.
function gameapp:init(fps)
--#if manager
  self.managers = {}
--#endif
  self.coroutine_runner = coroutine_runner()

  self.fps = fps
  self.delta_time = 1 / fps
  self.initial_gamestate = nil

--#if debug_menu
  self.debug_paused = false
  self.debug_spritesheet = false
--#endif
end

--#if manager

-- Return a sequence of newly instantiated managers
-- You must override this in order to have your managers instantiated and registered on start
-- They may be managers provided by the engine or custom managers.
-- In this engine, we prefer injection to having a configuration with many flags
--   to enable/disable certain managers.
-- We can still override on_update/on_render on the game app directly for custom effects,
--   but prefer handling them in managers when possible. Note that update and render
--   order will follow the strict order in which the managers have been registered,
--   and that managers will always update before the gamestate, but render after the gamestate.
-- Call this in your derived gameapp with all the managers you need during the game.
-- You can then access the manager from any gamestate with self.app.managers[':type']
function gameapp:instantiate_managers()
  -- override ex:
  -- return {my_manager1(), my_manager2(), my_manager3()}
  return {}
end

-- Register the managers you want to update and render, providing backward ref to app
function gameapp:register_managers(managers)
  for manager in all(managers) do
    manager.app = self
    self.managers[manager.type] = manager
  end
end

function gameapp:instantiate_and_register_managers()
  self:register_managers(self:instantiate_managers())
end

--#endif

-- Return a sequence of newly instantiated gamestates
-- This is preferred to passing gamestate references directly
--   to avoid two apps sharing the same gamestates
-- You must override this in order to have your gamestates instantiated and registered on start
-- Char count optimization: to reduce char count and because all game applications should
--  define at least 1 gamestate, we don't define a base implementation, but keep it commented
--  below to serve as an example
--[[
function gameapp:instantiate_gamestates()
  -- override ex:
  -- return {my_gamestate1(), my_gamestate2(), my_gamestate3()}
  return {}
end
--]]

-- Register gamestats, adding them to flow, providing backward ref to app
function gameapp:register_gamestates(gamestates)
  for state in all(gamestates) do
    state.app = self
    flow:add_gamestate(state)
  end
end

function gameapp:instantiate_and_register_gamestates()
  self:register_gamestates(self:instantiate_gamestates())
end

-- unlike init, init_modules is called later, after finishing the configuration
-- in pico-8, it must be called in the global init function
function gameapp:start()
--#if manager
  self:on_pre_start()

  self:instantiate_and_register_managers()
--#endif

  self:instantiate_and_register_gamestates()

  -- REFACTOR: consider making flow a very generic manager, that knows the initial gamestate
  -- and is only added if you want (but mind the start/update/render order)
  assert(self.initial_gamestate ~= nil, "gameapp:start: gameapp.initial_gamestate is not set")
  flow:query_gamestate_type(self.initial_gamestate)

--#if manager
  for _, manager in pairs(self.managers) do
    manager:start()
  end
--#endif

--#if debug_menu
  menuitem(1, "debug pause", function() self.debug_paused = not self.debug_paused end)
  menuitem(2, "debug spritesheet", function() self.debug_spritesheet = not self.debug_spritesheet end)
--#endif

--#if manager
  self:on_post_start()
--#endif
end

--#if manager

-- override to initialize custom managers
function gameapp:on_pre_start() -- virtual
end

-- override to initialize custom managers
function gameapp:on_post_start() -- virtual
end

--#endif

--#if itest
function gameapp:reset()
  self.coroutine_runner:stop_all_coroutines()

  -- clear input (important to avoid "sticky" keys if we switch to another itest just
  --   while some keys are simulated down)
  input:init()

  -- clear flow (this will remove any added gamestate, which can then be re-added in start > register_gamestates)
  flow:init()

  self:on_reset()
end

-- override to call :init on your custom managers, or to reset anything set up in
-- in gameapp:start/on_start, really
function gameapp:on_reset() -- virtual
end
--#endif

function gameapp:update()
--#if debug_menu
  if self.debug_paused then
    self:handle_debug_pause_input()

    -- skip completely the update this frame, including input processing
    -- this allows us to resume input processing on time resume, taking into account
    --  events like button release properly
    -- in counterpart, handle_debug_pause_input will have to use PICO-8 API
    --  directly like btn()
    return
  end
--#endif

  -- advance game by 1 frame
  self:step()
end

--#if debug_menu
function gameapp:handle_debug_pause_input()
  -- same system as integrationtest (see itest_manager:handle_input)
  if btnp(button_ids.right) then
    -- advance step
    self:step()
  elseif btnp(button_ids.down) then
    -- skip 10 steps
    for i = 1, 10 do
      self:step()
    end
  elseif btnp(button_ids.x) then
    -- exit debug pause (will be effective next frame)
    self.debug_paused = false
  end
end
--#endif

function gameapp:step()
  input:process_players_inputs()

  self.coroutine_runner:update_coroutines()

--#if manager
  for _, manager in pairs(self.managers) do
    if manager.active then
      manager:update()
    end
  end
--#endif

  flow:update()

  self:on_update()
end

-- override to add custom update behavior
function gameapp:on_update() -- virtual
end

function gameapp:draw()
  cls()

  flow:render()

--#if manager
  -- managers tend to draw stuff on top of the rest, so render after flow (i.e. gamestate)
  for _, manager in pairs(self.managers) do
    if manager.active then
      manager:render()
    end
  end
--#endif

--#if debug_menu
  if self.debug_spritesheet then
    -- this will draw the entire spritesheet on screen (since it makes exactly 128x128
    --  if we also use the shared memory)
    -- note that it will use the current transparent color (black by default)
    spr(0, 0, 0, 16, 16)
  end
--#endif

--#if manager
  -- we don't have a layered rendering system, so to support overlays
  -- on top of any manager drawing, we just add a render_post
  flow:render_post()
--#endif

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
--[[#pico8
--#if ultrafast
  delay_s = delay_s / 2
--#endif
--#pico8]]

  -- the delay in frames may be fractional, and we want to wait for the last frame
  --   to be fully completed, so ceil
  yield_delay(ceil(delay_s * self.fps))
end

return gameapp
