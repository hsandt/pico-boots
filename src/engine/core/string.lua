-- exceptionally a global require
-- make sure to require it in your common_game.lua too if using minify lv3
-- for early definition (if using unify, redundant require will be removed)
require("engine/core/string_split")

-- String helpers

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

--#if deprecated
-- deprecated: use tonum instead, whose bug (0x0000.0001 offset on negative values)
-- was fixed in PICO-8 0.1.12
function string_tonum(val)
  warn("string_tonum is deprecated, use tonum instead")
  return tonum(val)
end
--#endif

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
