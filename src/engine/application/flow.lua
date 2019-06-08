-- flow: module that registers and updates gamestates
--  it also handles transitions between gamestates, but they must be manually queried
--  (no condition-based transition)
-- it relies on gamestate objects, for which an abstract class is defined in gamestate.lua.
-- you can also pass any table that implements the interface suggested in gamestate.lua, such as
-- a singleton (if you need auto-init and access from anywhere)
--
-- we recommend to use the `gameapp` class for big projects, as it handles flow init and update
--  under a layer of abstraction. you will still need to query gamestate to change state, though.

-- example usage if using `flow` directly instead of `gameapp`:
--
-- [in dedicated modules, define some gamestate classes `gamestate1` and `gamestate2`
--  of resp. types "state1" and "state2" by deriving `gamestate`]

-- [in your main init:]
-- flow:add_gamestate(gamestate1())
-- flow:add_gamestate(gamestate2())
-- flow:query_gamestate_type("state1")
-- [or]
-- flow:query_gamestate_type(gamestate1.type)
--
-- [then in your main update:]
-- flow:update()
--
-- [and in your main render:]
-- flow:render()
--
-- [when you want to change state:]
-- flow:query_gamestate_type("state2")

require("engine/core/class")
--#if log
local logging = require("engine/debug/logging")
--#endif

-- flow singleton
-- state vars
-- curr_state   gamestates     current gamestate
-- next_state   gamestates     next gamestate, nil if no transition expected
local flow = singleton(function (self)
  -- parameters
  self.gamestates = {}

  -- state vars
  self.curr_state = nil
  self.next_state = nil
end)

function flow:update()
  self:_check_next_state()
  if self.curr_state then
    self.curr_state:update()
  end
end

function flow:render()
  if self.curr_state then
    self.curr_state:render()
  end
end

-- add a gamestate
-- currently, we are not asserting if gamestate has already been added,
--  as there are some places in utests that add the same gamestate twice,
--  but it would definitely be cleaner
function flow:add_gamestate(gamestate)
  assert(gamestate ~= nil, "flow:add_gamestate: passed gamestate is nil")
  self.gamestates[gamestate.type] = gamestate
end

-- query a new gamestate
function flow:query_gamestate_type(gamestate_type)
  assert(gamestate_type ~= nil, "flow:query_gamestate_type: passed gamestate_type is nil")
  assert(self.curr_state == nil or self.curr_state.type ~= gamestate_type, "flow:query_gamestate_type: cannot query the current gamestate type '"..gamestate_type.."' itself")
  self.next_state = self.gamestates[gamestate_type]
  assert(self.next_state ~= nil, "flow:query_gamestate_type: gamestate type '"..gamestate_type.."' has not been added to the flow gamestates")
end

-- check if a new gamestate was queried, and enter it if so
function flow:_check_next_state(gamestate_type)
  if self.next_state then
    self:_change_state(self.next_state)
  end
end

-- enter a new gamestate
function flow:_change_state(new_gamestate)
  assert(new_gamestate ~= nil, "flow:_change_state: cannot change to nil gamestate")
  if self.curr_state then
    self.curr_state:on_exit()
  end
  self.curr_state = new_gamestate
  new_gamestate:on_enter()
  self.next_state = nil  -- clear any gamestate query
end

--#if itest
-- check if a new gamestate was queried, and enter it if so (convenient for itests)
function flow:change_gamestate_by_type(gamestate_type)
  assert(self.gamestates[gamestate_type] ~= nil, "flow:change_gamestate_by_type: gamestate type '"..gamestate_type.."' has not been added to the flow gamestates")
  self:_change_state(self.gamestates[gamestate_type])
end
--#endif

-- export
return flow
