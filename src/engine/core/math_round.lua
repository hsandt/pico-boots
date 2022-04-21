-- return value rounded at [decimals_count (default 0)] decimals
function round(value, decimals_count)
  decimals_count = decimals_count or 0

  -- work with absolute value (we always round ties away from zero)
  -- ex: -2.35 -> 2.35
  local abs_value = abs(value)

  -- compute power of ten factor to shift decimals to the left
  --  temporary, to extract the number of decimals we are interested in
  -- ex: 1 decimal -> factor 10
  local factor = 10 ^ decimals_count

  -- shift by wanted number of decimals to the left, and floor
  -- ex: 2.35 with 1 decimal -> 23.5 -> 23
  local upscaled_abs_value = factor * abs_value
  local floored_upscaled_abs_value = flr(upscaled_abs_value)

  local rounded_upscaled_abs_value

  -- check for remaining decimals for rounding up/down
  -- ex: 23.5 - 23 = 0.5
  if upscaled_abs_value - floored_upscaled_abs_value >= 0.5 then
    -- round up
    -- ex: 23.5 -> 24
    rounded_upscaled_abs_value = (floored_upscaled_abs_value + 1)
  else
    -- round down (floor)
    -- ex: 23.4 -> 23
    rounded_upscaled_abs_value = floored_upscaled_abs_value
  end

  -- finally, re-add the sign, and downscale the rounded value back
  -- ex: [-] * 24 / 10 = -2.4
  return sgn(value) * rounded_upscaled_abs_value  / factor
end
