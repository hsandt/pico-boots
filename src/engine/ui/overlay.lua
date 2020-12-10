-- overlay class: allows to draw drawables on top of the screen
-- a drawable struct is a struct that implements a draw method
local overlay = new_class()

-- state vars
-- drawables_seq   {drawable}          sequence of {drawable} for drawing ordered by layer
--                                       (from background to foreground)
-- drawables_map   {string: drawable}  table mapping name => drawable for name-based search
function overlay:init()
  self.drawables_seq = {}
  self.drawables_map = {}
end

--#if tostring
function overlay:_tostring()
  local drawable_names = {}

  local pairs_callback = pairs
--#if dump
  pairs_callback = orderedPairs
--#endif

  for name, drawable in pairs_callback(self.drawables_map) do
    add(drawable_names, '"'..name..'"')
  end
  return "overlay(drawable names: {"..joinstr_table(", ", drawable_names).."})"
end
--#endif

-- add a drawable identified by a name, containing a text string,
-- at a position vector, with a given color
-- if a drawable with the same name already exists, copy properties to it
--  (the passed drawable is *not* kept in seq/map in this case)
-- adding the same drawable twice is possible, but not supported (see remove_drawable)
function overlay:add_drawable(name, drawable)
  local found_drawable = self.drawables_map[name]
  if found_drawable == nil then
    -- add passed drawable to sequence and add reference by name to map
    add(self.drawables_seq, drawable)
    self.drawables_map[name] = drawable
  else
    -- copy passed drawable properties to existing drawable
    -- since both seq and map hold a reference to it, this is enough
    found_drawable:copy_assign(drawable)
  end
end

-- remove a drawable identified by a name
-- if the drawable is not found, fails with warning
-- we don't support adding the same drawable twice with different names
--  so if you try to remove such a drawable, the first found (layer the most behind)
--  will be removed from the sequence even if you passed the name of the second one
--  or further (map will remove exactly the one with name, though)
function overlay:remove_drawable(name)
  local found_drawable = self.drawables_map[name]
  if found_drawable ~= nil then
    -- for a table (without __eq), del must take the exact reference to the table
    del(self.drawables_seq, found_drawable)
    self.drawables_map[name] = nil
  else
    warn("overlay:remove_drawable: could not find drawable with name: '"..name.."'", 'ui')
  end
end

-- remove all the drawables
function overlay:clear_drawables()
  clear_table(self.drawables_seq)
  clear_table(self.drawables_map)
end

-- draw all drawables in the overlay, last elements on top
function overlay:draw()
  for drawable in all(self.drawables_seq) do
    drawable:draw()
  end
end

return overlay
