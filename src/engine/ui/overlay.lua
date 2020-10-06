local label = require("engine/ui/label")

-- overlay class: allows to draw labels on top of the screen
local overlay = new_class()

-- parameters
-- layer       int              level at which the overlay should be drawn, higher on top
-- state vars
-- labels      {string: label}  table of labels to draw, identified by name
function overlay:init(layer)
  self.layer = layer
  self.labels = {}
end

--#if tostring
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
    warn("overlay:add_label no colour passed, will default to black (0)", 'ui')
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
    warn("overlay:remove_label: could not find label with name: '"..name.."'", 'ui')
  end
end

-- remove all the labels
function overlay:clear_labels()
  clear_table(self.labels)
end

-- draw all labels in the overlay. order is not guaranteed
function overlay:draw_labels()
  for _, label in pairs(self.labels) do
    label:draw()
  end
end

return overlay
