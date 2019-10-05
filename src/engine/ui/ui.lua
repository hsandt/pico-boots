--#if log
local logging = require("engine/debug/logging")
--#endif

require("engine/core/math")
local input = require("engine/input/input")

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

-- return the top-left position where to print some `text`
--  so it appears centered at (`center_x`, `center_y`)
-- newlines are not supported
-- text: string
-- center_pos: vector
function ui.center_to_topleft(text, center_x, center_y)
  -- a character in pico-8 has a width of 3px + space 1px = 4px,
  --  a height of 5px + line space 1px = 6px (we don't support newlines but it's even)
  -- so text half-width is #text * 4 / 2, half-height is 6 / 2 = 3
  return center_x - #text * 2, center_y - 3
end

-- print `text` centered around (`center_x`, `center_y`) with `color`
function ui.print_centered(text, center_x, center_y, color)
  local x, y = ui.center_to_topleft(text, center_x, center_y)
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

  -- draw border (segments overlap 1px at the corners)
  line(x0, y0, x1, y0, border_color)
  line(x1, y0, x1, y1, border_color)
  line(x1, y1, x0, y1, border_color)
  line(x0, y1, x0, y0, border_color)

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

-- label struct: container for a text to draw at a given position
local label = new_struct()

-- text      printable  text content to draw (mainly string or number)
-- position  vector     position to draw the label at
-- colour    int        color index to draw the label with
function label:_init(text, position, colour)
  self.text = text
  self.position = position
  self.colour = colour
end

--#if log
function label:_tostring()
  return "label('"..self.text.."' @ "..self.position.." in "..color_tostring(self.colour)..")"
end
--#endif

-- overlay class: allows to draw labels on top of the screen
local overlay = new_class()

-- parameters
-- layer       int              level at which the overlay should be drawn, higher on top
-- state vars
-- labels      {string: label}  table of labels to draw, identified by name
function overlay:_init(layer)
  self.layer = layer
  self.labels = {}
end

--#if log
function overlay:_tostring()
  return "overlay(layer: "..self.layer..")"
end
--#endif

-- add a label identified by a name, containing a text string,
-- at a position vector, with a given color
-- if a label with the same name already exists, replace it
function overlay:add_label(name, text, position, colour)
  if not colour then
    colour = colors.black
    warn("overlay:add_label no colour passed, will default to black (0)", "ui")
  end
  if self.labels[name] == nil then
    -- create new label and add it
    self.labels[name] = label(text, position, colour)
  else
    -- set existing label properties
    local label = self.labels[name]
    label.text = text
    label.position = position
    label.colour = colour
  end
end

-- remove a label identified by a name
-- if the label is not found, fails with warning
function overlay:remove_label(name, text, position)
  if self.labels[name] ~= nil then
    self.labels[name] = nil
  else
    warn("overlay:remove_label: could not find label with name: '"..name.."'", "ui")
  end
end

-- remove all the labels
function overlay:clear_labels()
  clear_table(self.labels)
end

-- draw all labels in the overlay. order is not guaranteed
function overlay:draw_labels()
  for name, label in pairs(self.labels) do
    api.print(label.text, label.position.x, label.position.y, label.colour)
  end
end


-- export
ui.label = label
ui.overlay = overlay
return ui
