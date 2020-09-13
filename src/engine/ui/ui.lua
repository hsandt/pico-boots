require("engine/core/string")
local input = require("engine/input/input")

alignments = {
  left = 1,
  horizontal_center = 2,
  center = 3,
  right = 4
}

local ui = {
  cursor_sprite_data = nil
}

-- setup

--#if mouse

-- injection function: call it from game to set the sprite data
-- for the mouse cursor. this avoids accessing game data
-- from an engine script
-- cursor_sprite_data  sprite_data
function ui:set_cursor_sprite_data(cursor_sprite_data)
  self.cursor_sprite_data = cursor_sprite_data
end

-- helper functions

function ui:render_mouse()
  if input.mouse_active and self.cursor_sprite_data then
    camera(0, 0)
    local cursor_position = input.get_cursor_position()
    self.cursor_sprite_data:render(cursor_position)
  end
end

--#endif

-- return the left position where to print some `text`
--  so it appears x-centered at `center_x`
-- multi-line text is not supported, so split your string
--  into lines before passing it to this function
-- text: string
-- center_x: vector
function ui.center_x_to_left(text, center_x)
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
function ui.center_y_to_top(text, center_y)
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
function ui.center_to_topleft(text, center_x, center_y)
  -- a character in pico-8 has a width of 3px + space 1px = 4px (character_width)
  --  a height of 5px + line space 1px = 6px (character_height)
  -- so text half-width is #text * 4 / 2, half-height is 6 / 2 = 3
  -- then we re-add 1 on x and y so the visual center of a character is really at the center
  --   which gives center_x - #text * 2 + 1, center_y - 3 + 1
  -- (it's just to make the expression more compact than if using constants)
  return ui.center_x_to_left(text, center_x), ui.center_y_to_top(text, center_y)
end

-- print `text` centered around (`center_x`, `center_y`) with color `col`
-- multi-line text is supported
function ui.print_centered(text, center_x, center_y, col)
  local lines = strspl(text, '\n')

  -- center on y too (character_height / 2 = 3)
  center_y = center_y - (#lines - 1) * 3

  for l in all(lines) do
    local x, y = ui.center_to_topleft(l, center_x, center_y)
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
function ui.print_aligned(text, x, y, alignment, color)
  if alignment == alignments.center then
    x, y = ui.center_to_topleft(text, x, y)
  elseif alignment == alignments.horizontal_center then
    x = ui.center_x_to_left(text, x)
  elseif alignment == alignments.right then
    -- user passed position of right edge of text,
    -- so go to the left by text length, +1 since there an extra 1px interval
    x = x - #text * character_width + 1
  end
  api.print(text, x, y, color)
end

-- draw a box between x0, y0, x1 and y1 (bottom to top and right to left arguments are supported)
function ui.draw_box(x0, y0, x1, y1, border_color, fill_color)
  -- if coordinates are not top to bottom and left to right, swap them so our calculations with fill are correct
  if x0 > x1 then
    local x = x0
    x0 = x1
    x1 = x
  end
  if y0 > y1 then
    local y = y0
    y0 = y1
    y1 = y
  end

  -- draw border
  rect(x0, y0, x1, y1, border_color)

  -- fill rectangle if big enough to have an interior
  if x0 + 1 <= x1 - 1 and y0 + 1 <= y1 - 1 then
    rectfill(x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill_color)
  end
end

-- draw a rounded box between x0, y0, x1 and y1 (bottom to top and right to left arguments are supported)
-- only 1 pixel is removed from each corner
function ui.draw_rounded_box(x0, y0, x1, y1, border_color, fill_color)
  -- if coordinates are not top to bottom and left to right, swap them so our calculations with fill are correct
  if x0 > x1 then
    local x = x0
    x0 = x1
    x1 = x
  end
  if y0 > y1 then
    local y = y0
    y0 = y1
    y1 = y
  end

  -- draw border, cutting corners
  line(x0 + 1, y0, x1 - 1, y0, border_color)
  line(x1, y0 + 1, x1, y1 - 1, border_color)
  line(x1 - 1, y1, x0 + 1, y1, border_color)
  line(x0, y1 - 1, x0, y0 + 1, border_color)

  -- fill rectangle if big enough to have an interior
  if x0 + 1 <= x1 - 1 and y0 + 1 <= y1 - 1 then
    rectfill(x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill_color)
  end
end

-- draw a gauge with frame between x0, y0, x1 and y1 (bottom to top and right to left arguments are supported)
--   with a given fill ratio, filled toward given direction: directions
function ui.draw_gauge(x0, y0, x1, y1, fill_ratio, fill_direction, border_color, background_color, fill_color)
  -- if coordinates are not top to bottom and left to right, swap them so our calculations with fill are correct
  if x0 > x1 then
    local x = x0
    x0 = x1
    x1 = x
  end
  if y0 > y1 then
    local y = y0
    y0 = y1
    y1 = y
  end

  -- draw border
  rect(x0, y0, x1, y1, border_color)

  -- fill rectangle if big enough to have an interior
  if x0 + 1 <= x1 - 1 and y0 + 1 <= y1 - 1 then
    rectfill(x0 + 1, y0 + 1, x1 - 1, y1 - 1, background_color)

    if fill_direction == directions.left or fill_direction == directions.right then
      local gauge_width = flr(fill_ratio * (x1 - x0 - 1))  -- padding of 1px each side
      if gauge_width >= 1 then
        if fill_direction == directions.right then
          rectfill(x0 + 1, y0 + 1, x0 + gauge_width, y1 - 1, fill_color)
        else  -- fill_direction == directions.left
          rectfill(x1 - gauge_width, y0 + 1, x1 - 1, y1 - 1, fill_color)
        end
      end
    else  -- vertical direction
      local gauge_height = flr(fill_ratio * (y1 - y0 - 1))  -- padding of 1px each side
      if gauge_height >= 1 then
        if fill_direction == directions.down then
          rectfill(x0 + 1, y0 + 1, x1 - 1, y0 + gauge_height, fill_color)
        else  -- fill_direction == directions.up
          rectfill(x0 + 1, y1 - gauge_height, x1 - 1, y1 - 1, fill_color)
        end
      end
    end
  end
end

return ui
