-- overlay class: allows to draw drawables on top of the screen
-- a drawable struct is a struct that implements a draw method
local overlay = new_class()

-- state vars
-- drawables      {string: drawable}  table of drawables to draw, identified by name
function overlay:init()
  self.drawables = {}
end

--#if tostring
function overlay:_tostring()
  local drawable_names = {}
  local pairs_callback = pairs
  -- if #dump is used, print drawable names in alphabetical order
--#if dump
  pairs_callback = orderedPairs
--#endif
  for name, _lab in pairs_callback(self.drawables) do
    add(drawable_names, '"'..name..'"')
  end
  return "overlay(drawable names: {"..joinstr_table(", ", drawable_names).."})"
end
--#endif

-- add a drawable identified by a name, containing a text string,
-- at a position vector, with a given color
-- if a drawable with the same name already exists, replace it
function overlay:add_drawable(name, drawable)
  if self.drawables[name] == nil then
    -- create new drawable and add it
    self.drawables[name] = drawable
  else
    -- set existing drawable properties
    self.drawables[name]:copy_assign(drawable)
  end
end

-- remove a drawable identified by a name
-- if the drawable is not found, fails with warning
function overlay:remove_drawable(name)
  if self.drawables[name] ~= nil then
    self.drawables[name] = nil
  else
    warn("overlay:remove_drawable: could not find drawable with name: '"..name.."'", 'ui')
  end
end

-- remove all the drawables
function overlay:clear_drawables()
  clear_table(self.drawables)
end

-- draw all drawables in the overlay. order is not guaranteed
function overlay:draw()
  for _, drawable in pairs(self.drawables) do
    drawable:draw()
  end
end

return overlay
