-- String case helpers

local string_case = {}

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

function string_case.to_big(str)
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

return string_case
