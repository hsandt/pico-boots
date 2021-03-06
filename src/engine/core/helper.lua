-- table algorithms

-- implementation of "map", "apply" or "transform" in other languages
--  (as "map" means something else in pico8)
-- support both sequences and generic tables (that includes tables with nil in the middle)
function transform(t, func)
  local transformed_t = {}
  -- pairs will iterate in any order, but even sequences will be properly transformed
  --  as long as transform order doesn't matter (and it should, as func should be a pure function)
  for key, value in pairs(t) do
    transformed_t[key] = func(value)
  end
  return transformed_t
end

--[[
usage example with a class/struct as callable:

```
local pair = new_struct()

function pair:_init(first, second)
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

function contains(t, searched_value)
  for key, value in pairs(t) do
    if value == searched_value then
      return true
    end
  end
  return false
end

-- return true if the table is empty (contrary to #t == 0,
--  it also supports non-sequence tables)
function is_empty(t)
  for k, v in pairs(t) do
    return false
  end
  return true
end

-- clear a table
function clear_table(t)
 for k in pairs(t) do
  t[k] = nil
 end
end

--#if assert
-- return a table reversing keys and values, assuming the original table is injective
-- this is "assert" only because we mostly need it to generate enum-to-string tables
function invert_table(t)
  inverted_t = {}
  for key, value in pairs(t) do
    inverted_t[value] = key
  end
  return inverted_t
end
--#endif

-- wait for nb_frames. only works if you update your coroutines each frame.
function yield_delay(nb_frames)
  -- we want to continue the coroutine as soon as the last frame
  -- has been reached, so we don't want to yield the last time, hence -1
  for frame = 1, nb_frames - 1 do
    yield()
  end
end
