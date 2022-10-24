-- sprite object class: a drawable that supports motion interpolation
-- allows to combine sprite data or sspr data with a visible flag and
--  transform members for immediate draw without passing arguments
-- unsupported: angle, but easy to add as member if we want
local sprite_object = new_class()

-- sprite_data      sprite_data|sspr_data    sprite data used to draw
-- visible          bool                     drawn iff true
-- position         vector                   position to draw at (default: (0, 0))
-- flip_x           bool                     if true, draw flipped horizontally
-- flip_y           bool                     if true, draw flipped vertically
-- scale            number                   scale to draw at (default: 1)
function sprite_object:init(sprite_data_ref, position, flip_x, flip_y, scale)
  assert(sprite_data_ref)
  self.sprite_data = sprite_data_ref
  self.visible = true

  -- copy position to avoid modifying original table by reference later
  self.position = position and position:copy() or vector.zero()

  self.flip_x = flip_x
  self.flip_y = flip_y
  self.scale = scale or 1
end

-- draw this sprite using sprite_data at position
-- note that we name this 'draw' and not 'render' to match drawable API suggested by ui_animation
function sprite_object:draw()
  if self.visible then
    -- for now, we don't support angle
    self.sprite_data:render(self.position, self.flip_x, self.flip_y, 0, self.scale)
  end
end

return sprite_object
