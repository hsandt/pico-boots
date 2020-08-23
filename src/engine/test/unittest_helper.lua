-- helper for unitests
-- mostly used by pico8 utests (that miss busted assertions),
--  the functions are also useful to define busted-only struct deep equality

-- return true if t1 and t2 have the same recursive content:
--  - if t1 and t2 are tables, if they have the same keys and values,
--   if use_mt_equality is true, table values with metatable __eq method are compared by ==,
--    but tables without __eq are still compared by content
--   if use_mt_equality is false, tables are compared by pure content, as in busted assert.are_same
--    however, keys are still compared with ==
--    (simply because it's more complicated to check all keys for deep equality, and rarely useful)
--  - else, if they have the same values (if different types, it will return false)
-- if use_mt_equality is false but use_mt_equality_from_2nd_level is true,
--  only start using metatable __eq for values inside t1 and t2, not t1 and t2 themselves
-- this is useful if you want to compare raw content at the first level but delegate equality for embedded structs
--  (if use_mt_equality is true, use_mt_equality_from_2nd_level does nothing)
function are_same(t1, t2, use_mt_equality, use_mt_equality_from_2nd_level)
  -- use_mt_equality and use_mt_equality_from_2nd_level default to false
  --  (we count on nil being falsy here), so default to raw content comparison
  -- it is what we think busted should do (but in practice it does something similar
  --  to passing use_mt_equality_from_2nd_level = true because embedded structs use their
  --  defined __eq if any...)

  if type(t1) ~= 'table' or type(t2) ~= 'table' then
    -- we have at least one non-table argument, compare by equality
    -- if both arguments have different types, it will return false
    return t1 == t2
  end

  -- both arguments are tables, check meta __eq

  local mt1 = getmetatable(t1)
  local mt2 = getmetatable(t2)
  if (mt1 and mt1.__eq or mt2 and mt2.__eq) and use_mt_equality then
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
    if not are_same(v1, v2, use_mt_equality or use_mt_equality_from_2nd_level) then
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

function are_same_with_message(t, passed, use_mt_equality, use_mt_equality_from_2nd_level)
  if use_mt_equality == nil then
    use_mt_equality = false
  end
  if use_mt_equality_from_2nd_level == nil then
    use_mt_equality_from_2nd_level = false
  end
  local result = are_same(t, passed, use_mt_equality, use_mt_equality_from_2nd_level)
  -- apparently, messages below are too long for PICO-8 to print, so if running p8utests,
  --  you can temporarily printh the messages directly to the console
  if result then
    -- passed is not same as t, return false with does_not_contain message (will appear when using assert(not are_same(...)))
    return true, "Expected objects to not be the same (use_mt_equality: "..tostr(use_mt_equality)..", use_mt_equality_from_2nd_level: "..tostr(use_mt_equality_from_2nd_level)..").\nPassed in:\n"..nice_dump(passed).."\nDid not expect:\n"..nice_dump(t)
  else
    -- the message is not as good as luassert element by element comparison, but if you really need this
    --  you can customize this implement to show a star on the first non-matching element (would need to reimplement
    --  are_same to output precise information on why false was returned)
    return false, "Expected objects to be the same (use_mt_equality: "..tostr(use_mt_equality)..", use_mt_equality_from_2nd_level: "..tostr(use_mt_equality_from_2nd_level)..").\nPassed in:\n"..nice_dump(passed).."\nExpected:\n"..nice_dump(t)
  end
end
