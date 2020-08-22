-- helper for unitests executed in pico8, that miss busted assertions

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

function are_same_with_message(t, passed, compare_raw_content)
  if compare_raw_content == nil then
    compare_raw_content = false
  end
  local result = are_same(t, passed, compare_raw_content)
  if result then
    -- passed is not same as t, return false with does_not_contain message (will appear when using assert(not are_same(...)))
    return true, "Expected objects to not be the same (compare_raw_content: "..tostr(compare_raw_content)..").\nPassed in:\n"..nice_dump(passed).."\nDid not expect:\n"..nice_dump(t)
  else
    return false, "Expected objects to be the same (compare_raw_content: "..tostr(compare_raw_content)..").\nPassed in:\n"..nice_dump(passed).."\nExpected:\n"..nice_dump(t)
  end
end
