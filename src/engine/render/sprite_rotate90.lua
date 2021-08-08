-- Draw a sprite rotated by an angle multiple of 90 degrees:
--  located at tile (i ,j) in spritesheet, at (x, y) px on screen,
--  spanning on w tiles to the right, h tiles to the bottom
--  (like spr, w and h may be fractional to allow partial sprites, although not tested),
--  optionally flipped on X and Y with flags flip_x and flip_y,
--  offset by -(pivot_x, pivot_y) and rotated by an angle *multiple of 90 degrees* around this pivot,
--  ignoring transparent_color.
--
-- w and h must be passed
-- flip_x ad flip_y are optional, defaults to nil => falsy
-- angle is optional, defaults to 0
-- transparent_color_bitmask is optional, defaults to black as only transparent color
--
-- It mimics native spr() and therefore doesn't use pico-boots math vectors.
-- Unlike spr() though, it takes sprite location coords i, j as first arguments
--  instead of sprite ID n, but conversion is trivial.
-- It replaces the more expensive spr_r which relies on trigonometry and backward calculation with target disc
-- since rotating a rectangle just gives a perfect rectangle
--
-- Reference: ToyCrab's implementation on https://www.lexaloffle.com/bbs/?tid=41129 and some conventions taken from spr_r
-- But it needed a full adaptation to spr_r's API which has more parameters and uses an angle
--  rather than a mode enum.
-- Note that the 2nd answer by freds72 suggests a very performant implementation using tline,
--  but requires to use some map memory.
-- Profiling shows that the pset implementation was still very good, with visible CPU peak when showing
--  rotated sprites on screen, unlike spr_r, so this implementation was selected and adapted,
--  as it needs less setup and no map memory usage.
function spr_r90(i, j, x, y, w, h, flip_x, flip_y, pivot_x, pivot_y, angle, transparent_color_bitmask)
  -- to spare tokens, we don't give defaults to all values like angle = 0 or transparent_color = 0
  --  user should call function with all parameters; if not using angle, we recommend using spr() directly
  angle = angle or 0

  assert(0 <= angle and angle < 1, "angle "..angle.." is not between 0 and 1 (excluded), please % 1 yourself")
  assert(angle % 0.25 == 0, "angle "..angle.." is not a multiple of 0.25 (90 deg)")

  if angle >= 0.5 then
    -- 0.5 or 0.75 => reduce to 0 or 0.25, subtituting 0.5 for a 180 rotation <=> flip on X and Y
    -- in other words, by using flip when needed, we only ever need to rotate the sprite by up to 90 degrees
    angle = angle - 0.5
    flip_x = not flip_x
    flip_y = not flip_y
  end

  if angle == 0 then
    -- native sprite function can do the job

    -- flip pivot on x or y if needed
    local actual_pivot_x = flip_x and w * tile_size - pivot_x or pivot_x
    local actual_pivot_y = flip_y and h * tile_size - pivot_y or pivot_y

    -- set transparency and draw sprite
    palt(transparent_color_bitmask)
    spr(16 * j + i, x - actual_pivot_x, y - actual_pivot_y, w, h, flip_x, flip_y)
    palt()
  else
    -- angle == 0.75 here
    -- precompute pixel values from tile indices: sprite source top-left, sprite size
    local sx = tile_size * i
    local sy = tile_size * j
    local sw = tile_size * w
    local sh = tile_size * h

    -- support flipping by changing start and iteration direction of target pixel position
    -- no need to change start dx/dy when flipping:
    --  since we're working from pivot, the difference to pivot is enough
    local dx_mult = flip_x and -1 or 1
    local dy_mult = flip_y and -1 or 1

    for dx = 0, sw - 1 do
      for dy = 0, sh - 1 do
        local c = sget(sx + dx, sy + dy)
        if band(color_to_bitmask(c), transparent_color_bitmask) == 0 then
          -- rotation by 90: x contributes to -y, y contributes to +x
          -- same offset subtlety as in spr_r: our pivot is actually placed at a crosspoint
          --  between 4 pixels, located at the top-left of the position (pivot_x, pivot_y)
          -- therefore, to get the correct offset when facing negative displacement,
          --  we need to remove 0.5 from the pivot (will do nothing on positive contribution,
          --  but will be floored to the previous integer coord on negative contribution)
          -- since we compute the difference dz - pivot_z, this gives:
          --  dz - (pivot_z - 0.5) = dz - pivot_z + 0.5 for z = x or y
          pset(x + dy_mult * (dy - pivot_y + 0.5), y - dx_mult * (dx - pivot_x + 0.5), c)
        end
      end
    end
  end
end
