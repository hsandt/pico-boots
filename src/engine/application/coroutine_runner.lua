local class = require("engine/core/class")
require("engine/core/coroutine")
local class = require("engine/core/helper")
local logging = require("engine/debug/logging")

local coroutine_runner = new_class()

function coroutine_runner:_init()
  -- sequence of coroutine_curry
  self.coroutine_curries = {}

  -- store the last error in coresume here, just the time to assert with it
  self.last_error = nil
end

-- create and register coroutine with optional arguments
-- ! for methods, remember to pass the instance it*self* as first optional argument !
function coroutine_runner:start_coroutine(async_function, ...)
--[[#pico8
  coroutine = cocreate(async_function)
--#pico8]]
--#if busted
  coroutine = cocreate(self:make_safe(async_function))
--#endif
  add(self.coroutine_curries, coroutine_curry(coroutine, ...))
end

-- update emit coroutine if active, remove if dead
function coroutine_runner:update_coroutines()
  local coroutine_curries_to_del = {}
  for i, coroutine_curry in pairs(self.coroutine_curries) do
    local status = costatus(coroutine_curry.coroutine)
    if status == "suspended" then
      -- resume the coroutine and assert if failed
      -- (assertions don't work from inside coroutines, but will make coresume return false)
      -- pass the curry arguments now (most of the time they are only useful
      --   on the 1st coresume call, since other times they are just yield() return values)
      -- note that vanilla lua allows to yield values that would be returned after `result`,
      --   but pico-8 doesn't
      local result = coresume(coroutine_curry.coroutine, unpack(coroutine_curry.args))
--#if log
      -- Avoid asserting on one line with potentially complex concatenation, as arguments are evaluated
      --   in advance. Note that it should now be dead.
      if not result then
        assert(false, "coroutine update failed (now dead) with: "..self.last_error)
      end
--#endif
    elseif status == "dead" then
      -- register the coroutine for removal from the sequence (don't delete it now since we are iterating over it)
      -- note that this block is only entered on the frame after the last coresume
      add(coroutine_curries_to_del, coroutine_curry)
    else  -- status == "running"
      warn("coroutine_runner:update_coroutines: coroutine should not be running outside its body: "..coroutine_curry, "flow")
    end
  end
  -- delete dead coroutines
  for coroutine_curry in all(coroutine_curries_to_del) do
    del(self.coroutine_curries, coroutine_curry)
  end
end

function coroutine_runner:stop_all_coroutines()
  clear_table(self.coroutine_curries)
end

--#if busted
-- Decorate function with a safe pcall (busted only)
--
-- Generic enough to be used with any risky function, even not async,
--   but we use specifically for coroutines, as any runtime error
--   that occurs inside a coresume will simply return a false result,
--   without any error message; which we will return with pcall.
-- Since this is made for PICO-8 coroutines which don't support return values,
--   we ignore the return value if the call succeeds.
-- We could store the result to use it, but this would only work with busted anyway.
function coroutine_runner:make_safe(async_function)
  return function (...)
    local status, retval = pcall(async_function, ...)
    if not status then
      -- no need to error with the actual message, such messages are invisible inside coroutine anyway
      -- instead, store the error message as a member and just error to trigger the assert in
      -- update_coroutines
      self.last_error = retval
      error("invisible error")
    end
  end
end
--#endif

return coroutine_runner
