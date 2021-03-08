-- String size helpers

-- exceptionally a global require
-- make sure to require it in your common_game.lua too if using minify lv3
-- for early definition (if using unify, redundant require will be removed)
require("engine/core/string_split")

local string_size = {}

-- return (number of chars in the longest line, number of lines),
--   in a multi-line string
-- logic is close to wtk.label.compute_size but does not multiply by char size
--   to return size in pixels
function string_size.compute_char_size(text)
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
function string_size.compute_size(text)
  local max_nb_chars, nb_lines = string_size.compute_char_size(text)
  return max_nb_chars * character_width + 1, nb_lines * character_height + 1
end

return string_size
