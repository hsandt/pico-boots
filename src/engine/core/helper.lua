-- sequence helpers

-- create an enum from a sequence of variant names
-- Minification warning: this won't support aggressive minification
--   unless all variants start with "_", or enum variants are always accessed
--   with my_enum["key"] or my_enum[key], since table keys are dynamically defined
function enum(variant_names)
  local t = {}
  local i = 1

  for variant_name in all(variant_names) do
    t[variant_name] = i
    i = i + 1
  end

  return t
end

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

-- return true if t1 and t2 have the same recursive content:
--  - if t1 and t2 are tables, if they have the same keys and values,
--   if compare_raw_content is false, table values with __eq method are compared by ==,
--    but tables without __eq are still compared by content
--   if compare_raw_content is true, tables are compared by pure content, as in busted assert.are_same
--    however, keys are still compared with ==
--    (simply because it's more complicated to check all keys for deep equality, and rarely useful)
--  - else, if they have the same values (if different types, it will return false)
-- if no_deep_raw_content is true, do not pass the compare_raw_content parameter to deeper calls
--  this is useful if you want to compare content at the first level but delegate equality for embedded structs
function are_same(t1, t2, compare_raw_content, no_deep_raw_content)
  -- compare_raw_content and no_deep_raw_content default to false (we count on nil being falsy here)

  if type(t1) ~= 'table' or type(t2) ~= 'table' then
    -- we have at least one non-table argument, compare by equality
    -- if both arguments have different types, it will return false
    return t1 == t2
  end

  -- both arguments are tables, check meta __eq

  local mt1 = getmetatable(t1)
  local mt2 = getmetatable(t2)
  if (mt1 and mt1.__eq or mt2 and mt2.__eq) and not compare_raw_content then
    -- we are not comparing raw content and equality is defined, use it
    return t1 == t2
  end

  -- we must compare keys and values

  -- first iteration: check that all keys of t1 are in t2, with the same value
  for k1, v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil then
      -- t2 misses key k1 that t1 has
      return false
    end
    if not are_same(v1, v2, compare_raw_content and not no_deep_raw_content) then
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


-- string helpers

-- Upper/lower conversion. PICO-8 reverses case by displaying lower characters as big upper chars,
--   and upper characters as small upper chars (scaled down a bit, but same shape as upper chars).
-- https://www.lexaloffle.com/bbs/?tid=3217
-- although we do the reverse of what is suggested (small to big) since we just want to sanitize
--   copy-pasted strings that contain upper-case characters into pure lower-case characters
--   (so they appear big in PICO-8)
local small_to_big_chars = {}
-- upper A to Z character codes (displayed as smaller A to Z in PICO-8)
local small_chars = "\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90"
local big_chars = "abcdefghijklmnopqrstuvwxyz"
for i=1,26 do
  small_to_big_chars[sub(small_chars, i, i)] = sub(big_chars, i, i)
end

function to_big(str)
  local big_str = ""
  for i = 1, #str do
    local c = sub(str, i, i)
    if c >= "\65" and c <= "\90" then
      big_str = big_str..small_to_big_chars[c]
    else
      big_str = big_str..c
    end
  end
  return big_str
end

-- alternative to tonum that only works with strings (and numbers
--   thanks to sub converting them implicitly)
-- it fixes the 0x0000.0001 issue on negative number strings
-- UPDATE: expect native tonum to be fixed in 0.1.12
-- https://www.lexaloffle.com/bbs/?pid=63583
function string_tonum(val)
  -- inspired by cheepicus's workaround in
  -- https://www.lexaloffle.com/bbs/?tid=3780
  if sub(val, 1, 1) == '-' then
    local abs_num = tonum(sub(val, 2))
    assert(abs_num, "could not parse absolute part of number: '-"..sub(val, 2).."'")
    return - abs_num
  else
    local num = tonum(val)
    assert(num, "could not parse number: '"..val.."'")
    return num
  end
end

-- wait for nb_frames. only works if you update your coroutines each frame.
function yield_delay(nb_frames)
  -- we want to continue the coroutine as soon as the last frame
  -- has been reached, so we don't want to yield the last time, hence -1
  for frame = 1, nb_frames - 1 do
    yield()
  end
end
