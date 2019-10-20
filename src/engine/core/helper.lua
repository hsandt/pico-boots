require("engine/application/constants")

-- sequence helpers

-- create an enum from a sequence of variant names
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
function copy_seq(seq)
  local copied_seq = {}
  for value in all(seq) do
    add(copied_seq, value)
  end
  return copied_seq
end

-- filter a sequence following a condition function
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
-- only works on sequences
function transform(seq, func)
  local transformed_seq = {}
  for value in all(seq) do
    add(transformed_seq, func(value))
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

-- return a random element from a sequence
function pick_random(seq)
  assert(#seq > 0)

  -- mind the index starting at 1
  local random_index = random_int_bounds_inc(1, #seq)
  return seq[random_index]
end

--[[
usage example with a class/struct as callable:

```
require("engine/core/class")

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

-- return module members from their names as multiple values
-- use it after require("module") to define
--  local a, b = get_members(module, "a", "b")
--  for more simple access
function get_members(module, ...)
  local member_names = {...}
  return unpack(transform(member_names,
    function(member_name)
      return module[member_name]
    end)
  )
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

-- unpack from munpack at https://gist.github.com/josefnpat/bfe4aaa5bbb44f572cd0
function unpack(t, from, to)
  from = from or 1
  to = to or #t
  if from > to then return end
  return t[from], unpack(t, from+1, to)
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

--#if log

function stringify(value)
  if type(value) == 'table' and value._tostring then
    return value:_tostring()
  else
    return tostr(value)
  end
end

--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

This is only here to allow dump and nice_dump functions to be deterministic
by dumping elements with sorted keys (with an optional argument, as this is only possible
if the keys are comparable), hence easier to debug and test.

Source: http://lua-users.org/wiki/SortedIteration
Modification:
- updated API for modern Lua (# instead of getn)
]]

local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex)
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex(t)
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

local function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

--[[
return a precise variable content, including table entries.

for sequence containing nils, nil is not shown but nil's index will be skipped

if as_key is true and t is not a string, surround it with []

by default, table recursion will stop at a call depth of logger.dump_max_recursion_level
however, you can pass a custom number of remaining levels to see more

if use_tostring is true, use any implemented _tostring method for tables
you can also use dump on strings just to surround them with quotes


if sorted_keys is true, dump will try to sort the entries by key
only use this if you are sure that all the keys are comparable
(e.g. only numeric or only strings)

never use dump with use_tostring: true or nice_dump inside _tostring
to avoid infinite recursion => out of memory error
--]]
function dump(dumped_value, as_key, level, use_tostring, sorted_keys)
  if as_key == nil then
    as_key = false
  end

  level = level or 2

  if use_tostring == nil then
    use_tostring = false
  end

  if sorted_keys == nil then
    sorted_keys = false
  end

  local repr

  if type(dumped_value) == "table" then
    if use_tostring and dumped_value._tostring then
      repr = dumped_value:_tostring()
    else
      if level > 0 then
        local entries = {}
        local pairs_callback
        if sorted_keys then
          pairs_callback = orderedPairs
        else
          pairs_callback = pairs
        end
        for key, value in pairs_callback(dumped_value) do
          local key_repr = dump(key, true, level - 1, use_tostring, sorted_keys)
          local value_repr = dump(value, false, level - 1, use_tostring, sorted_keys)
          add(entries, key_repr.." = "..value_repr)
        end
        repr = "{"..joinstr_table(", ", entries).."}"
      else
        -- we already surround with [], so even if as_key, don't add extra []
        return "[table]"
      end
    end
  else
    -- for most types
    repr = tostr(dumped_value)
  end

  -- non-string keys must be surrounded with [] (only once), string values with ""
  if as_key and type(dumped_value) ~= "string" and sub(repr, 1, 1) ~= "[" then
    repr = "["..repr.."]"
  elseif not as_key and type(dumped_value) == "string" then
    repr = "\""..repr.."\""
  end

  return repr
end

-- dump using _tostring method when possible
-- don't use inside _tostring definition, see dump for warning
function nice_dump(value, sorted_keys)
  return dump(value, false, nil, true, sorted_keys)
end

-- dump a sequence as "{value1, value2, ...}" using stringify
-- (strings won't get surrounding quotes)
function dump_sequence(sequence)
  return "{"..joinstr_table(", ", sequence, nice_dump).."}"
end

-- concatenate a sequence of strings or stringables with a separator
-- embedded nil values won't be ignored, but nils at the end will be
-- if you need to surround strings with quotes, pass string_converter = nice_dump
--   but be careful not to use that in _tostring if one of the members are class/struct
--   themselves, as it may cause infinite recursion on _tostring => nice_dump => _tostring
function joinstr_table(separator, args, string_converter)
  string_converter = string_converter or stringify

  local n = #args

  local joined_string = ""

  -- iterate by index instead of for all, so we don't skip nil values
  -- and #n (which counts nil values) match the used index
  for index = 1, n do
    joined_string = joined_string..string_converter(args[index])
    if index < n then
      joined_string = joined_string..separator
    end
  end

  return joined_string
end

-- variadic version
-- (does not support string converter due to parameter being at the end)
function joinstr(separator, ...)
  return joinstr_table(separator, {...})
end

--#endif

-- https://pastebin.com/NS8rxMwH
-- converted to clean lua, adapted coding style
-- changed behavior:
-- - avoid adding next line if first word of line is too long
-- - don't add trailing space at end of line
-- - don't add eol at the end of the last line
-- - count the extra separator before next word in the line length prediction test
-- i kept the fact that we don't collapse spaces so 2x, 3x spaces are preserved

-- word wrap (string, char width)
function wwrap(s,w)
  local retstr = ''
  local lines = strspl(s, '\n')
  local nb_lines = count(lines)

  for i = 1, nb_lines do
    local linelen = 0
    local words = strspl(lines[i], ' ')
    local nb_words = count(words)

    for k = 1, nb_words do
      local wrd = words[k]
      local should_wrap = false

      if k > 1 then
        -- predict length after adding 1 separator + next word
        if linelen + 1 + #wrd > w then
          -- wrap
          retstr = retstr..'\n'
          linelen = 0
          should_wrap = true
        else
          -- don't wrap, so add space after previous word if not the first one
          retstr = retstr..' '
          linelen = linelen + 1
        end
      end

      retstr = retstr..wrd
      linelen = linelen + #wrd
    end

    -- wrap following \n already there
    if i < nb_lines then
      retstr = retstr..'\n'
    end
  end

  return retstr
end

-- return (number of chars in the longest line, number of lines),
--   in a multi-line string
-- logic is close to wtk.label.compute_size but does not multiply by char size
--   to return size in pixels
function compute_char_size(text)
  local lines = strspl(text, '\n')
  nb_lines = #lines

  local max_nb_chars = 0
  for line in all(lines) do
    max_nb_chars = max(max_nb_chars, #line)
  end

  return max_nb_chars, nb_lines
end

-- return (width, height) of a multi-single string,
--   adding a margin of 1px in each direction (to easily frame in rectangle)
-- result is close to wtk.label.compute_size but with extra 2px
--   in width and height
function compute_size(text)
  local max_nb_chars, nb_lines = compute_char_size(text)
  return max_nb_chars * character_width + 1, nb_lines * character_height + 1
end

-- port of lua string.split(string, separator)
-- separator must be only one character
-- added parameter collapse:
--  if true, collapse consecutive separators into a big one
--  if false or nil, handle each separator separately,
--   adding an empty string between each consecutive pair
-- ex1: strspl("|a||b", '|')       => {"", "a", "", "b"}
-- ex2: strspl("|a||b", '|', true) => {"a", "b"}
function strspl(s,sep,collapse)
  local ret = {}
  local buffer = ""

  for i = 1, #s do
    if sub(s, i, i) == sep then
      if #buffer > 0 or not collapse then
        add(ret, buffer)
        buffer = ""
      end
    else
      buffer = buffer..sub(s,i,i)
    end
  end
  if #buffer > 0 or not collapse then
    add(ret, buffer)
  end
  return ret
end

-- wait for nb_frames. only works if you update your coroutines each frame.
function yield_delay(nb_frames)
  -- we want to continue the coroutine as soon as the last frame
  -- has been reached, so we don't want to yield the last time, hence -1
  for frame = 1, nb_frames - 1 do
    yield()
  end
end
