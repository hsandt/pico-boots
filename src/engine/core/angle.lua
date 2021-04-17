-- Return signed delta from angle1 to angle2 (pico-8 angles) using the shortest path,
-- including the case where it crosses angle 0 (e.g. 0.9 to 0.1 -> 0.2, not -0.8)
-- Mind the sign convention, what we return is really angle2 - angle1 remapped to [-0.5, 0.5) via modulo
function compute_signed_angle_between(angle1, angle2)
  local raw_delta = angle2 - angle1
  return (raw_delta + 0.5) % 1 - 0.5
end
