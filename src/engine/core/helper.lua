-- sequence algorithms

-- return a copy of a sequence
--  (needs to be a proper sequence, nil in the middle will mess up indices)
function copy_seq(seq)
  local copied_seq = {}
  for value in all(seq) do
    add(copied_seq, value)
  end
  return copied_seq
end

-- filter a sequence following a condition function
--  (needs to be a proper sequence, nil in the middle will mess up indices)
function filter(seq, condition_func)
  local filtered_seq = {}
  for value in all(seq) do
    if condition_func(value) then
      add(filtered_seq, value)
    end
  end
  return filtered_seq
end

-- implementation of "map", "apply" or "transform" in other languages
--  (as "map" means something else in pico8)
-- support both sequences and generic tables (that includes tables with nil in the middle)
function transform(t, func)
  local transformed_seq = {}
  -- pairs will iterate in any order, but even sequences will be properly transformed
  --  as long as transform order doesn't matter (and it should, as func should be a pure function)
  for key, value in pairs(t) do
    transformed_seq[key] = func(value)
  end
  return transformed_seq
end

-- function decorator to create a function that receives
-- a sequence of arguments and unpacks it for the decorated function
function unpacking(f)
  return function (args)
    return f(unpack(args))
  end
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

-- lightweight version of unittest_helper.lua > are_same that doesn't check metatables
--  nor deep values of embedded tables, unless they have a defined equality
--  (typically because they are structs themselves)
-- we use this one for struct equality, so if you embed a table in a struct,
--  make sure this table is a struct itself for defined equality
-- the only reason we don't use are_same (which is stripped from build by the way)
--  is to reduce token count

-- return true if tables t1 and t2 have the same shallow content:
function are_same_shallow(t1, t2)
  -- we assume t1 and t2 are tables (struct in practice),
  --  so we must compare keys and values
  assert(type(t1) == 'table' and type(t2) == 'table')

  -- first iteration: check that all keys of t1 are in t2, with the same value
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil then
      -- t2 misses key k1 that t1 has
      return false
    end
    -- most of the time we compare POD at this point,
    --  but if v1 and v2 are tables with defined equality
    --  (mostly struct), this will delegate to stuct equality
    -- ! if plain table, they will be compared by ref/id !
    -- the only reason we don't recurse to are_same_shallow
    --  here and don't handle non-table type comparison at the top
    --  is to spare tokens... in counterpart, you must implement
    --  __eq manually for structs that contain pure tables
    -- (but if those structs are used in release build,
    --  better add recursion here as it would take ~15 tokens
    --  and your custom __eq would probably take as many tokens anyway)
    if v1 ~= v2 then
      return false
    end
  end

  -- second iteration: check that all keys of t2 are in t1. don't check values, it has already been done
  for k2, _ in pairs(t2) do
    if t1[k2] == nil then
      -- t1 misses key k2 that t2 has
      return false
    end
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
