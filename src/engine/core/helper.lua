-- table algorithms

-- implementation of "map", "apply" or "transform" in other languages
--  (as "map" means something else in pico8)
-- support both sequences and generic tables (that includes tables with nil in the middle)
function transform(tab, func)
  local transformed_tab = {}
  -- pairs will iterate in any order, but even sequences will be properly transformed
  --  as long as transform order doesn't matter (and it should, as func should be a pure function)
  for key, value in pairs(tab) do
    transformed_tab[key] = func(value)
  end
  return transformed_tab
end

--[[
usage example with a class/struct as callable:

```
require("engine/core/fun_helper")

local pair = new_struct()

function pair:init(first, second)
  self.first = first
  self.second = second
end

local pairs = transform({
    {1, "one"},
    {2, "two"},
    {3, "three"}
  }, unpacking(pair))

-- equivalent to:

local pairs = {
  pair(1, "one"),
  pair(2, "two"),
  pair(3, "three")
}

```

--]]


-- table helpers

function contains(tab, searched_value)
  for _, value in pairs(tab) do
    if value == searched_value then
      return true
    end
  end
  return false
end

-- return true if the table is empty (contrary to #t == 0,
--  it also supports non-sequence tables)
-- {nil} is considered empty (we don't care about all() iterating over nil)
function is_empty(tab)
  return next(tab) == nil
end

-- clear a table
function clear_table(tab)
 for k in pairs(tab) do
  tab[k] = nil
 end
end

--#if assert
-- return a table reversing keys and values, assuming the original table is injective
-- this is "assert" only because we mostly need it to generate enum-to-string tables
function invert_table(tab)
  inverted_tab = {}
  for key, value in pairs(tab) do
    inverted_tab[value] = key
  end
  return inverted_tab
end
--#endif

-- wait for nb_frames
-- only works if you update your coroutines each frame
-- note that yield_delay_frames(1) is equivalent to yield(),
--  and if you call yield_delay_frames(n), you must update coroutine
--  n times, at which point it will be stopped just after the last yield,
--  but alive; and only the *next* update (n+1-th) will continue the coroutine further
function yield_delay_frames(nb_frames)
  for frame = 1, nb_frames do
    yield()
  end
end

--#if deprecated
-- old version including - 1 to allow coroutine to continue immediately on n-th frame
-- it was deemed more misleading than the current version, as yield_delay_frames(1)
--  would do nothing, and thus deprecated
function yield_delay(nb_frames)
  yield_delay_frames(nb_frames - 1)
end
--#endif
