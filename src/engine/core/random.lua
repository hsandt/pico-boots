--#if log
local _logging = require("engine/debug/logging")
--#endif

-- return a random integer between 0 and range - 1
function random_int_range_exc(range)
  assert(range > 0)
  return flr(rnd(range))
end

-- return a random integer between lower and upper, included
-- equivalent to native math.random(lower, upper), but implemented for PICO-8
function random_int_bounds_inc(lower, upper)
  assert(lower <= upper)
  return lower + flr(rnd(upper - lower + 1))
end

--#if deprecated
-- return a random element from a sequence
function pick_random(seq)
  warn("DEPRECATED: please use rnd(seq) instead")
  assert(#seq > 0)
  return rnd(seq)
end
--#endif
