-- sprite object class
-- allows to combine sprite data with a visible flag and transform members for immediate draw without passing arguments
local sprite_object = new_class()

-- sprite_data               sprite_data         sprite data used to draw
-- visible                   bool                drawn iff true
-- position                  vector              position to draw at (default: (0, 0))
function sprite_object:init(sprite_data_ref, position)
  self.sprite_data = sprite_data_ref
  self.visible = true
  self.position = position or vector.zero()
end

-- draw this sprite using sprite_data at position
-- note that we name this 'draw' and not 'render' to match drawable API suggested by ui_animation
function sprite_object:draw()
  if self.visible then
    -- for now, we don't cover flip nor angle
    self.sprite_data:render(self.position)
  end
end

return sprite_object
