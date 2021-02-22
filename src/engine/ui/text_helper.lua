-- exceptionally a global require
-- make sure to require it in your common_game.lua too if using minify lv3
-- for early definition (if using unify, redundant require will be removed)
require("engine/core/string_split")
local outline = require("engine/ui/outline")

local text_helper = {}

-- https://pastebin.com/NS8rxMwH
-- converted to clean lua, adapted coding style
-- changed behavior:
-- - avoid adding next line if first word of line is too long
-- - don't add trailing space at end of line
-- - don't add eol at the end of the last line
-- - count the extra separator before next word in the line length prediction test
-- I kept the fact that we don't collapse spaces so 2x, 3x spaces are preserved
-- as a side effect, \n just at the end of a wrapped line will produce a double newline,
--  so depending on your design, you may want not to add an extra \n if there is already one

-- word wrap (string, char width)
function wwrap(s,w)
  local retstr = ''
  local lines = strspl(s, '\n')
  local nb_lines = count(lines)

  for i = 1, nb_lines do
    local linelen = 0
    local words = strspl(lines[i], ' ')
    local nb_words = count(words)

    for k = 1, nb_words do
      local wrd = words[k]
      local should_wrap = false

      if k > 1 then
        -- predict length after adding 1 separator + next word
        if linelen + 1 + #wrd > w then
          -- wrap
          retstr = retstr..'\n'
          linelen = 0
          should_wrap = true
        else
          -- don't wrap, so add space after previous word if not the first one
          retstr = retstr..' '
          linelen = linelen + 1
        end
      end

      retstr = retstr..wrd
      linelen = linelen + #wrd
    end

    -- wrap following \n already there
    if i < nb_lines then
      retstr = retstr..'\n'
    end
  end

  return retstr
end

-- return the left position where to print some `text`
--  so it appears x-centered at `center_x`
-- multi-line text is not supported, so split your string
--  into lines before passing it to this function
-- text: string
-- center_x: vector
function text_helper.center_x_to_left(text, center_x)
  -- a character in pico-8 has a width of 3px + space 1px = 4px (character_width)
  --   so text half-width is #text * character_width (4) / 2 = #text * 2
  -- then we re-add 1 on x so the visual x-center of a character is really in the middle
  -- (we make the expression more compact by not writing constants)
  return center_x - #text * 2 + 1
end

-- return the top position where to print some `text`
--  so it appears y-centered at `center_y`
-- multi-line text is not supported, so split your string
--  into lines before passing it to this function
-- text: string
-- center_y: vector
function text_helper.center_y_to_top(text, center_y)
  -- a character in pico-8 has a height of 5px + line space 1px = 6px (character_height)
  --   so text half-height is 6 / 2 = 3
  -- then we re-add 1 on y so the visual center of a character is really in the middle
  -- => center_y - 3 + 1
  -- (we make the expression more compact by not writing constants)
  return center_y - 2
end

-- return the top-left position where to print some `text`
--  so it appears centered at (`center_x`, `center_y`)
-- multi-line text is not supported, so split your string
--  into lines before passing it to this function
-- text: string
-- center_x: float
-- center_y: float
function text_helper.center_to_topleft(text, center_x, center_y)
  -- a character in pico-8 has a width of 3px + space 1px = 4px (character_width)
  --  a height of 5px + line space 1px = 6px (character_height)
  -- so text half-width is #text * 4 / 2, half-height is 6 / 2 = 3
  -- then we re-add 1 on x and y so the visual center of a character is really at the center
  --   which gives center_x - #text * 2 + 1, center_y - 3 + 1
  -- (it's just to make the expression more compact than if using constants)
  return text_helper.center_x_to_left(text, center_x), text_helper.center_y_to_top(text, center_y)
end

-- print `text` centered around (`center_x`, `center_y`) with color `col`
-- multi-line text is supported
function text_helper.print_centered(text, center_x, center_y, col)
  local lines = strspl(text, '\n')

  -- center on y too (character_height / 2 = 3)
  center_y = center_y - (#lines - 1) * 3

  for l in all(lines) do
    local x, y = text_helper.center_to_topleft(l, center_x, center_y)
    api.print(l, x, y, col)

    -- prepare offset for next line
    center_y = center_y + character_height
  end
end

-- print `text` at `x`, `y` with the given alignment, color `col` and
--  outline color `outline_col`
-- text: string
-- x: float
-- y: float
-- aligment: alignments
-- col: colors
-- outline_col: colors | nil
function text_helper.print_aligned(text, x, y, alignment, col, outline_color)
  if alignment == alignments.center then
    x, y = text_helper.center_to_topleft(text, x, y)
  elseif alignment == alignments.horizontal_center then
    x = text_helper.center_x_to_left(text, x)
  elseif alignment == alignments.right then
    -- user passed position of right edge of text,
    -- so go to the left by text length, +1 since there an extra 1px interval
    x = x - #text * character_width + 1
  end
  outline.print_with_outline(text, x, y, col, outline_color)
end

return text_helper
