-- source rectangle sprite data struct
-- equivalent of sprite_data, but uses sspr for rendering (render method has same interface for compatibility)
local sspr_data = new_struct()

-- sx, sy, sw, sh            int, int, int, int  sspr coordinates (source position and dimensions)
-- pivot                     vector              (0, 0)              reference center to draw (top-left is (0 ,0))
-- transparent_color_bitmask int (bitmask)       0b1000000000000000  color transparency bitmask used when drawing sprite, low-endian
function sspr_data:init(sx, sy, sw, sh, pivot, transparent_color_arg)
  self.sx, self.sy, self.sw, self.sh = sx, sy, sw, sh
  self.pivot = pivot or vector.zero()
  self.transparent_color_bitmask = generic_transparent_color_arg_to_mask(transparent_color_arg)
end

--#if tostring
function sspr_data:_tostring()
  -- binary would be ideal, but at least show transparent_color_bitmask in hexadecimal
  return "sspr_data("..joinstr(", ", self.sx, self.sy, self.sw, self.sh, self.pivot, tostr(self.transparent_color_bitmask, true))..")"
end
--#endif

-- draw this sprite at position, optionally flipped
-- this follows the common 'renderable' interface
-- position                  vector
-- flip_x                    bool (nil ok, interpreted as false)
-- flip_y                    bool (nil ok, interpreted as false)
-- angle                     angle multiple of 0.25 (90 degrees), between 0 and 1 (excluded) (default: 0)
--                           NOT SUPPORTED yet, but kept for compatibility with sprite_data interface,
--                           so animated_sprite can be agnostic about what kind of sprite data it uses
-- scale                     scale to draw at (default: 1)
function sspr_data:render(position, flip_x, flip_y, angle, scale)
  assert(not angle or angle % 1 == 0, "sspr_data:render: doesn't support non-0 angle "..tostr(angle).." yet")
  scale = scale or 1

  -- flip pivot on x or y if needed
  local actual_pivot_x = flip_x and self.sw - self.pivot.x or self.pivot.x
  local actual_pivot_y = flip_y and self.sh - self.pivot.y or self.pivot.y

  -- no need to strip unless #sprite_scale like sprite_data, since implementation is trivial as we're already using sspr anyway
  palt(self.transparent_color_bitmask)
  sspr(self.sx, self.sy, self.sw, self.sh, position.x - scale * actual_pivot_x, position.y - scale * actual_pivot_y, scale * self.sw, scale * self.sh, flip_x, flip_y)
  palt()
end

return sspr_data
