-- sprite data struct
local sprite_data = new_struct()

-- id_loc                    sprite_id_location                      sprite location on the spritesheet
-- span                      tile_vector         tile_vector(1, 1)   sprite span on the spritesheet
-- pivot                     vector              (0, 0)              reference center to draw (top-left is (0 ,0))
-- transparent_color_bitmask int (bitmask)       0b1000000000000000  color transparency bitmask used when drawing sprite, low-endian
function sprite_data:init(id_loc, span, pivot, transparent_color_arg)
  self.id_loc = id_loc
  self.span = span or tile_vector(1, 1)
  self.pivot = pivot or vector.zero()
  self.transparent_color_bitmask = generic_transparent_color_arg_to_mask(transparent_color_arg)
end

--#if tostring
function sprite_data:_tostring()
  -- binary would be ideal, but at least show transparent_color_bitmask in hexadecimal
  return "sprite_data("..joinstr(", ", self.id_loc, self.span, self.pivot, tostr(self.transparent_color_bitmask, true))..")"
end
--#endif

-- draw this sprite at position, optionally flipped
-- this follows the common 'renderable' interface
-- position                  vector
-- flip_x                    bool (nil ok, interpreted as false)
-- flip_y                    bool (nil ok, interpreted as false)
-- angle                     angle multiple of 0.25 (90 degrees), between 0 and 1 (excluded) (default: 0)
-- scale (#sprite_scale)     scale to draw at (default: 1)
function sprite_data:render(position, flip_x, flip_y, angle, scale)
-- scaling is stripped unless #sprite_scale to allow cartridges that don't need it to be minimal
--#if sprite_scale
  if scale and scale ~= 1 then
    assert(not angle or angle % 1 == 0, "sprite_data:render: doesn't support both angle "..angle.." and scale "..scale)

    local sw = 8 * self.span.i
    local sh = 8 * self.span.j

    -- flip pivot on x or y if needed
    local actual_pivot_x = flip_x and sw - self.pivot.x or self.pivot.x
    local actual_pivot_y = flip_y and sh - self.pivot.y or self.pivot.y

    palt(self.transparent_color_bitmask)
    sspr(8 * self.id_loc.i, 8 * self.id_loc.j, sw, sh, position.x - scale * actual_pivot_x, position.y - scale * actual_pivot_y, scale * sw, scale * sh, flip_x, flip_y)
    palt()
  else
--#endif
    spr_r90(self.id_loc.i, self.id_loc.j, position.x, position.y, self.span.i, self.span.j, flip_x, flip_y, self.pivot.x, self.pivot.y, angle, self.transparent_color_bitmask)
--#if sprite_scale
  end
--#endif
end

return sprite_data
