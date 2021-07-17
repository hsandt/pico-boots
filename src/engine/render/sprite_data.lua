-- sprite struct
local sprite_data = new_struct()

-- id_loc                    sprite_id_location                      sprite location on the spritesheet
-- span                      tile_vector         tile_vector(1, 1)   sprite span on the spritesheet
-- pivot                     vector              (0, 0)              reference center to draw (top-left is (0 ,0))
-- transparent_color_bitmask int (bitmask)       0b1000000000000000  color transparency bitmask used when drawing sprite, low-endian
function sprite_data:init(id_loc, span, pivot, transparent_color_arg)
  self.id_loc = id_loc
  self.span = span or tile_vector(1, 1)
  self.pivot = pivot or vector.zero()

  -- for transparent color, we support nil, a single color index, or a sequence of color indices
  if type(transparent_color_arg) == "table" then
    -- expecting a sequence of color indices
    self.transparent_color_bitmask = 0
    for c in all(transparent_color_arg) do
      -- use shl instead of << just so picotool doesn't fail
      self.transparent_color_bitmask = self.transparent_color_bitmask + color_to_bitmask(c)
    end
  elseif transparent_color_arg then
    -- expecting a single color index
    self.transparent_color_bitmask = color_to_bitmask(transparent_color_arg)
  else
    self.transparent_color_bitmask = color_to_bitmask(colors.black)
  end
end

--#if tostring
function sprite_data:_tostring()
  -- binary would be ideal, but at least show transparent_color_bitmask in hexadecimal
  return "sprite_data("..joinstr(", ", self.id_loc, self.span, self.pivot, tostr(self.transparent_color_bitmask, true))..")"
end
--#endif

-- draw this sprite at position, optionally flipped
-- position  vector
-- flip_x    bool
-- flip_y    bool
function sprite_data:render(position, flip_x, flip_y, angle)
  -- adjust pivot position if flipping

  local pivot = self.pivot:copy()

  if flip_x then
    -- flip pivot on x
    local spr_width = self.span.i * tile_size
    pivot.x = spr_width - pivot.x
  end

  if flip_y then
    -- flip pivot on y
    local spr_height = self.span.j * tile_size
    pivot.y = spr_height - pivot.y
  end

  if not angle or angle % 1 == 0 then
    -- no rotation, use native sprite function
    palt(self.transparent_color_bitmask)

    -- adjust draw position from pivot
    local draw_pos = position - pivot

    spr(self.id_loc:to_sprite_id(),
      draw_pos.x, draw_pos.y,
      self.span.i, self.span.j,
      flip_x, flip_y)

    palt()
  else
    -- sprite must be rotated, use custom drawing method
    -- TODO optimize CPU: spr_r is generic and supports any angle, but is also CPU expensive as it psets every pixel
    -- we should create a new function spr_r90 that specializes in rotations by multiples of 90:
    -- a. if angle == 0, change nothing
    -- b. if angle == 0.25, draw each horizontal line vertically using tline (https://www.lexaloffle.com/bbs/?tid=41129)
    -- c. if angle == 0.5, use flip X and flip Y
    -- d. if angle == 0.75, do like b but in reverse order
    -- note that tline will cost map memory so you may have to sacrifice a few map tiles, try to find tiles in the corner
    --  that are not visible by the camera...
    spr_r(self.id_loc.i, self.id_loc.j, position.x, position.y, self.span.i, self.span.j, flip_x, flip_y, pivot.x, pivot.y, angle, self.transparent_color_bitmask)
  end

end

return sprite_data
