require("engine/core/math_round")

-- convert a number value to a string, with the passed number of decimals
-- this always round the value with at target number of decimals,
--  so if you don't want this (e.g. for a timer with low precision, where you don't
--  want to show 2s where it's still 1.5s), you need to manually truncate the value
--  in the way you want (e.g. flr(value * (10 ^ decimals_count)) / (10 ^ decimals_count) )
function format_number(value, decimals_count)
  -- round the value (if not already) with the target number of decimals
  -- ex: 0.994 at 2 decimals -> 0.99
  -- ex: 0.995 at 2 decimals -> 1.00
  local rounded_value = round(value, decimals_count)

  -- extract absolute value and sign as string
  local sign_string = rounded_value < 0 and "-" or ""
  local abs_rounded_value = abs(rounded_value)

  -- extract integer part
  -- ex: 5.1 -> 5 -> "5"
  local abs_integer_part = flr(abs_rounded_value)
  local abs_integer_string = tostr(abs_integer_part)

  -- prepend sign if needed
  -- ex: "5" -> "-5"
  local integer_string = sign_string..abs_integer_string

  if decimals_count <= 0 then
    -- no decimals means no dot at all and no need to process decimal part,
    --  so return early with trivial integer string
    -- ex: "-5"
    return integer_string
  end

  -- extract decimal part
  -- ex: 5.1 -> 0.1
  local decimal_part = abs_rounded_value - abs_integer_part

  -- upscale by shifting decimals so we can handle it like an integer
  -- ex: 0.1 * 10 ^ 2 = 10
  local upscaled_decimal = decimal_part * 10 ^ decimals_count

  -- convert to string, rounding the value again to avoid inexact decimal representation
  --  in binary (e.g. 5.1 is internally represented as 0x0005.1999 which would, for 2 decimals,
  --  have its decimal string as "09" and show up as "5.09" instead of "5.10")
  -- note the flr(), which is only used to convert the result to an int,
  --  so decimal_string is formatted as "[number]" without dot nor 0 decimals,
  --  otherwise we'll have 2 decimal dots e.g. "-5.10.0"!
  -- finally, tostr will fix any inexact value representation issue
  -- ex: decimal part 0.1 -> "10" (and not "09")
  local raw_decimal_string = tostr(flr(round(upscaled_decimal)))

  -- pad with zeroes for any missing digit compared to target decimals count
  -- note: don't try a numerical approach of shifting digits by multiplying decimal part
  --  by 10 step by step and checking if floored integer part is positive...
  --  it will fail on inexact representations like 5.1 mentioned above, requiring hacks like
  --  checking if upscaled decimal part > 0.99, etc.
  -- instead, use a pragmatic approach by actually using the length of the raw decimal string,
  --  as tostr took care of turning inexact decimal values into exact expected strings
  -- ex: decimal part 0.1 needs no padding
  -- ex: decimal part 0.01 needs 1 padding ("0")
  local padding_zeroes_count = decimals_count - #raw_decimal_string
  local padding_zeroes = ""
  for i = 1, padding_zeroes_count do
      padding_zeroes = padding_zeroes.."0"
  end

  -- concatenate for full decimal string
  -- ex: decimal part 0.01 -> "01"
  local decimal_string = padding_zeroes..raw_decimal_string

  -- ex: -5.01
  return integer_string.."."..decimal_string
end
