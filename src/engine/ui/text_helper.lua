require("engine/core/string_split")

local text_helper = {}

alignments = {
  left = 1,
  horizontal_center = 2,
  center = 3,
  right = 4
}

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

-- print `text` at `x`, `y` with the given alignment and `color`
-- text: string
-- x: float
-- y: float
-- aligment: alignments
-- color: colors
function text_helper.print_aligned(text, x, y, alignment, color)
  if alignment == alignments.center then
    x, y = text_helper.center_to_topleft(text, x, y)
  elseif alignment == alignments.horizontal_center then
    x = text_helper.center_x_to_left(text, x)
  elseif alignment == alignments.right then
    -- user passed position of right edge of text,
    -- so go to the left by text length, +1 since there an extra 1px interval
    x = x - #text * character_width + 1
  end
  api.print(text, x, y, color)
end

return text_helper
