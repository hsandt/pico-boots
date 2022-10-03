-- sspr object class: a drawable that supports motion interpolation
-- equivalent of sprite object for sspr calls, useful when dealing with sprites whose covered tiles
--  are overlapping other sprites, so we need to slice sub-tiles with pixel precision
-- unsupported parameters: pivot, scale, flip, angle
local sspr_object = new_class()

-- sx, sy, sw, sh         int, int, int, int  sspr coordinates (source position and dimensions)
-- visible                bool                drawn iff true
-- transparent_color_bitmask int (bitmask)    0b1000000000000000  color transparency bitmask used when drawing sprite, low-endian
-- position               vector              position to draw at (default: (0, 0))
function sspr_object:init(sx, sy, sw, sh, transparent_color_arg, position)
  self.sx, self.sy, self.sw, self.sh = sx, sy, sw, sh
  self.visible = true
  self.transparent_color_bitmask = generic_transparent_color_arg_to_mask(transparent_color_arg)
  -- copy position to avoid modifying original table by reference later
  self.position = position and position:copy() or vector.zero()
end

-- draw this sspr using sspr source coordinates/dimensions, at current position
-- note that we name this 'draw' and not 'render' to match drawable API suggested by ui_animation
function sspr_object:draw()
  if self.visible then
    palt(self.transparent_color_bitmask)
    sspr(self.sx, self.sy, self.sw, self.sh, self.position.x, self.position.y)
    palt()
  end
end

return sspr_object
