-- return a random integer between 0 and range - 1
function random_int_range_exc(range)
  assert(range > 0)
  return flr(rnd(range))
end

-- return a random integer between lower and upper, included
function random_int_bounds_inc(lower, upper)
  assert(lower <= upper)
  return lower + flr(rnd(upper - lower + 1))
end

-- return a random element from a sequence
function pick_random(seq)
  assert(#seq > 0)

  -- mind the index starting at 1
  local random_index = random_int_bounds_inc(1, #seq)
  return seq[random_index]
end
