local animated_sprite = require("engine/render/animated_sprite")

--[[
Child class of animated_sprite embedding render parameters (position, flip, angle, scale)
to allow direct parameterless draw() call, making it a drawable class

This is useful when working with drawables, moving them via async methods, etc.

This is the animated equivalent of sprite_object.

Currently unsupported: angle

--]]

-- Note that the class is very similar to sprite_object, so we could factorize both to
--  create a generic class wrapper renderable_to_drawable that moves render parameters
--  inside the class, but currently sprite_object is using composition, while this
--  class is using inheritance (so we can just call update, play, etc.), so we'd need
--  to pick one model and apply it everywhere
local animated_sprite_object = derived_class(animated_sprite)

-- New attributes
-- visible                bool                    drawn iff true
-- position               vector                  position to draw at (default: (0, 0))
-- flip_x                 bool                    if true, draw flipped horizontally
-- flip_y                 bool                    if true, draw flipped vertically
-- scale                  number                  scale to draw at (default: 1)
function animated_sprite_object:init(data_table, position, flip_x, flip_y, scale)
  -- base constructor
  animated_sprite.init(self, data_table)

  self.visible = true

  -- copy position to avoid modifying original table by reference later
  self.position = position and position:copy() or vector.zero()

  self.flip_x = flip_x
  self.flip_y = flip_y
  self.scale = scale or 1
end

-- draw this sprite using sprite_data at position
-- note that we name this 'draw' and not 'render' to match drawable API suggested by ui_animation
function animated_sprite_object:draw()
  if self.visible then
    -- call base render method
    -- for now, we don't support angle
    self:render(self.position, self.flip_x, self.flip_y, 0, self.scale)
  end
end

return animated_sprite_object
