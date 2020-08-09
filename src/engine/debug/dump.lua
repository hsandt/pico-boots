--#if log

require("engine/core/string")

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

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

--[[
return a precise variable content, including table entries.

for sequence containing nils, nil is not shown but nil's index will be skipped

if as_key is true and t is not a string, surround it with []

by default, table recursion will stop at a call depth of 2
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

--(log)
--#endif

--[[#pico8
--#ifn log
--#if assert

-- some asserts use dump functions, so when building with `assert` but not `log` symbols,
--   we need some fallback
function dump(dumped_value, as_key, level, use_tostring, sorted_keys)
  return tostr(dumped_value)
end

function nice_dump(value)
  return tostr(value)
end

-- same definition, but we must repeat it because we don't have "||" support for #if log || assert
-- alternatively, we could define symbol `dump`, implied by `log` and `assert`, to simplify preprocessor conditions
function dump_sequence(sequence)
  return "{"..joinstr_table(", ", sequence, nice_dump).."}"
end

function stringify(value)
  return tostr(value)
end

--#endif
--#endif
--#pico8]]
