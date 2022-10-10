local coroutine_curry = require("engine/core/coroutine_curry")

local coroutine_runner = new_class()

function coroutine_runner:init()
  -- sequence of coroutine_curry
  self.coroutine_curries = {}
end

-- create and register coroutine with optional arguments
--  then return the index of the coroutine created (to allow future control such as stop_coroutine)
-- ! for methods, remember to pass the instance it*self* as first optional argument !
function coroutine_runner:start_coroutine(async_function, ...)
--[[#pico8
  local coroutine = cocreate(async_function)
--#pico8]]
--#if busted
  local coroutine = cocreate(self:make_safe(async_function))
--#endif
  add(self.coroutine_curries, coroutine_curry(coroutine, ...))
  return #self.coroutine_curries
end

-- update emit coroutine if active, remove if dead
function coroutine_runner:update_coroutines()
  local coroutine_curries_to_del = {}
  for i, coroutine_curry in pairs(self.coroutine_curries) do
    assert(coroutine_curry.coroutine, "coroutine_runner:update_coroutines: coroutine curry #"..i.." has empty coroutine (for args: "..nice_dump(coroutine_curry.args)..")")
    local status = costatus(coroutine_curry.coroutine)
    if status == "suspended" then
      -- resume the coroutine and assert if failed
      -- (assertions don't work from inside coroutines, but will make coresume return false)
      -- pass the curry arguments now (most of the time they are only useful
      --   on the 1st coresume call, since other times they are just yield() return values)
      -- note that vanilla lua allows to yield values that would be returned after `result`,
      --   but pico-8 doesn't
      -- PICO-8 lua is capable of returning caught error in second value, if not yielded values
      local result, error = coresume(coroutine_curry.coroutine, unpack(coroutine_curry.args))
--#if assert
      -- Avoid asserting on one line with potentially complex concatenation, as arguments are evaluated
      --   in advance. Note that the coroutine should now be dead.
      if not result then
        -- Both PICO-8 and busted support coresume error, but busted will try to
        -- add traceback info using xpcall (see make_safe function)
        -- Sometimes, error happens to be a table { message = "actual error message" }
        -- Not sure why, but in case it happens, just dump it. Note that traceback will
        -- fail to be added in busted in this situation (and it never shows in PICO-8 anyway)
        local error_msg = "coroutine update failed (now dead)"
        error_msg = error_msg.." with:\n"..dump(error)
--[[#pico8
        error_msg = error_msg.."\n"..trace(coroutine_curry.coroutine)
--#pico8]]
        if logging.logger and logging.logger.active_categories['coroutine'] then
          err("coroutine_runner:update_coroutines: "..error_msg, "coroutine")
        else
          -- fallback error when #log is not defined or 'coroutine' category is not logged,
          --  so we can at least see the message in console, which is more readable that the assert message
          --  in PICO-8
          printh("[coroutine] error: coroutine_runner:update_coroutines: "..error_msg)
        end
        assert(false, error_msg)
      end
--#endif
    elseif status == "dead" then
      -- register the coroutine for removal from the sequence (don't delete it now since we are iterating over it)
      -- note that this block is only entered on the frame after the last coresume
      add(coroutine_curries_to_del, coroutine_curry)
--#if log
    else  -- status == "running"
      warn("coroutine_runner:update_coroutines: coroutine should not be running outside its body: "..coroutine_curry, "coroutine")
--#endif
    end
  end
  -- delete dead coroutines
  for coroutine_curry in all(coroutine_curries_to_del) do
    del(self.coroutine_curries, coroutine_curry)
  end
end

function coroutine_runner:stop_coroutine(index)
  deli(self.coroutine_curries, index)
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
    -- use xpcall + traceback to get actual error + traceback in result
    local ok, result = xpcall(async_function, debug.traceback, ...)
    if not ok then
      -- Send the error upward to coresume using Lua error()
      -- this will make the interface uniform with PICO-8, since both PICO-8
      -- and busted will only care about the error returned by coresume
      -- The only difference is adding traceback info.
      error(result)
    end
  end
end
--#endif

return coroutine_runner
