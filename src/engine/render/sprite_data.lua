require("engine/render/color")

-- sprite struct
local sprite_data = new_struct()

-- id_loc                    sprite_id_location                      sprite location on the spritesheet
-- span                      tile_vector         tile_vector(1, 1)   sprite span on the spritesheet
-- pivot                     vector              (0, 0)              reference center to draw (top-left is (0 ,0))
-- transparent_color         colors              colors.black        color transparency used when drawing sprite
function sprite_data:_init(id_loc, span, pivot, transparent_color)
  self.id_loc = id_loc
  self.span = span or tile_vector(1, 1)
  self.pivot = pivot or vector.zero()
  self.transparent_color = transparent_color or colors.black
end

--#if log
function sprite_data:_tostring()
  return "sprite_data("..joinstr(", ", self.id_loc, self.span, self.pivot, self.transparent_color)..")"
end
--#endif

-- draw this sprite at position, optionally flipped
-- position  vector
-- flip_x    bool
-- flip_y    bool
function sprite_data:render(position, flip_x, flip_y)
  set_unique_transparency(self.transparent_color)

  local pivot = self.pivot:copy()

  -- caution: we don't support sprites smaller than
  --   the tile span (multiple of 8 in both directions)
  -- this means that flipping is always done relative
  --   to the central axes of the whole sprite
  --   (using tile span)
  -- so always center your sprites in your x8 tile group
  -- unfortunately, if the center is right inside a pixel
  --   (when width/height is odd), you need to make a choice
  --   by moving the sprite either to the left or right by 0.5px
  --   from its actual center, and balance that position in code
  --   besides flipping

  if flip_x then
    -- flip pivot on x
    local spr_width = self.span.i * tile_size
    pivot.x = spr_width - self.pivot.x
  end

  if flip_y then
    -- flip pivot on y
    local spr_height = self.span.j * tile_size
    pivot.y = spr_height - self.pivot.y
  end

  local draw_pos = position - pivot

  spr(self.id_loc:to_sprite_id(),
    draw_pos.x, draw_pos.y,
    self.span.i, self.span.j,
    flip_x, flip_y)

  palt()
end

return sprite_data
