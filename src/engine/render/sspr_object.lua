-- sspr object class: a drawable that supports motion interpolation
-- equivalent of sprite object for sspr calls, useful when dealing with sprites whose covered tiles
--  are overlapping other sprites, so we need to slice sub-tiles with pixel precision
-- unsupported: flip, angle (flip easy to add as member, angle not supported by sspr_data:render itself)
local sspr_object = new_class()

-- sspr_data              sspr_data           source rectangle sprite data used to draw
-- visible                bool                drawn iff true
-- position               vector              position to draw at (default: (0, 0))
-- scale                  number              scaleto draw at (default: 1)
function sspr_object:init(sspr_data_ref, position, scale)
  assert(sspr_data_ref)
  self.sspr_data = sspr_data_ref
  self.visible = true
  -- copy position to avoid modifying original table by reference later
  self.position = position and position:copy() or vector.zero()
  self.scale = scale or 1
end

-- draw this sspr using sspr source coordinates/dimensions, at current position
-- note that we name this 'draw' and not 'render' to match drawable API suggested by ui_animation
function sspr_object:draw()
  if self.visible then
    -- for now, we don't cover flip nor angle
    self.sspr_data:render(self.position, false, false, 0, self.scale)
  end
end

return sspr_object
