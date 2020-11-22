-- overlay class: allows to draw drawables on top of the screen
-- a drawable struct is a struct that implements a draw method
local overlay = new_class()

-- state vars
-- named_drawables   {string, drawables}  sequence of {name, drawable} to draw, from background to foreground
function overlay:init()
  self.named_drawables = {}
end

--#if tostring
function overlay:_tostring()
  local drawable_names = {}
  for named_drawable in all(self.named_drawables) do
    local name = named_drawable[1]
    add(drawable_names, '"'..name..'"')
  end
  return "overlay(drawable names: {"..joinstr_table(", ", drawable_names).."})"
end
--#endif

-- return reference to existing named_drawable in named_drawables
--  for drawable added with passed name,
--  or nil if so such drawable is found
function overlay:get_named_drawable(name)
  -- we prefer storing a sequence to a map to guarantee iteration order during draw,
  --  so we can define drawing layers from the order in which we add drawables,
  --  without passing an extra layer argument and having to sort the drawables
  -- in counterpart, finding a drawable is O(N) instead of O(1) (as we don't cache map)
  local found_drawable_index = seq_find_condition(self.named_drawables, function (named_drawable)
    return named_drawable[1] == name
  end)
  return found_drawable_index and self.named_drawables[found_drawable_index] or nil
end

-- add a drawable identified by a name, containing a text string,
-- at a position vector, with a given color
-- if a drawable with the same name already exists, replace it
function overlay:add_drawable(name, drawable)
  local found_named_drawable = self:get_named_drawable(name)
  if found_named_drawable == nil then
    -- create new drawable and add it
    add(self.named_drawables, {name, drawable})
  else
    -- set existing drawable properties
    found_named_drawable[2]:copy_assign(drawable)
  end
end

-- remove a drawable identified by a name
-- if the drawable is not found, fails with warning
function overlay:remove_drawable(name)
  local found_named_drawable = self:get_named_drawable(name)
  if found_named_drawable ~= nil then
    -- for a table (without __eq), del must take the exact reference to the table
    del(self.named_drawables, found_named_drawable)
  else
    warn("overlay:remove_drawable: could not find drawable with name: '"..name.."'", 'ui')
  end
end

-- remove all the drawables
function overlay:clear_drawables()
  clear_table(self.named_drawables)
end

-- draw all drawables in the overlay, last elements on top
function overlay:draw()
  for named_drawable in all(self.named_drawables) do
    named_drawable[2]:draw()
  end
end

return overlay
