local label = require("engine/ui/label")

-- overlay class: allows to draw labels on top of the screen
local overlay = new_class()

-- state vars
-- labels      {string: label}  table of labels to draw, identified by name
function overlay:init()
  self.labels = {}
end

--#if tostring
function overlay:_tostring()
  return "overlay("..#self.labels.." label(s))"
end
--#endif

-- add a label identified by a name, containing a text string,
-- at a position vector, with a given color
-- if a label with the same name already exists, replace it
function overlay:add_label(name, text, position, colour, outline_colour)
  if not colour then
    colour = colors.black
    warn("overlay:add_label no colour passed, will default to black (0)", 'ui')
  end

  local lab = label(text, position, colour, outline_colour)

  if self.labels[name] == nil then
    -- create new label and add it
    self.labels[name] = lab
  else
    -- set existing label properties
    self.labels[name]:copy_assign(lab)
  end
end

-- remove a label identified by a name
-- if the label is not found, fails with warning
function overlay:remove_label(name)
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
