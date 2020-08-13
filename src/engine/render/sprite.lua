-- Draw a rotated sprite:
--  located at tile (i ,j) in spritesheet, at (x, y) px on screen,
--  spanning on w tiles to the right, h tiles to the bottom,
--  optionally flipped on X and Y with flags flip_x and flip_y,
--  offset by -(pivot_x, pivot_y) and rotated by angle around this pivot,
--  ignoring transparent_color.
-- It mimics native spr() and therefore doesn't use pico-boots math vectors.
-- Adapted from jihem's spr_r function for "Rotating a sprite around its center"
-- https://www.lexaloffle.com/bbs/?pid=52525
-- Changes:
-- - replaced 8 with tile_size for semantics (no behavior change)
-- - w and h don't default to 1 since we use this function with sprite_data which already defaults span to (1, 1)
-- - support flipping
-- - support custom pivot (not always centered)
-- - angle is passed directly as PICO-8 angle between 0 and 1 (no division by 360, counter-clockwise sign convention)
-- - support transparent_color
-- - fixed %8 and /8 -> %16 and /16 since there are 16 sprites per row
--    in the spritesheet
-- - fixed yy<=sh -> yy<sh to avoid drawing an extra line from neighbor sprite
function spr_r(i, j, x, y, w, h, flip_x, flip_y, pivot_x, pivot_y, angle, transparent_color)
  -- precompute pixel values from tile indices: sprite source top-left, sprite size
  local sx = tile_size * i
  local sy = tile_size * j
  local sw = tile_size * w
  local sh = tile_size * h

  -- precompute angle trigonometry
  local sa = sin(angle)
  local ca = cos(angle)

  -- precompute "target disc": where we must draw pixels of the rotated sprite (relative to (x, y))
  -- the image of a rectangle rotated by any angle from 0 to 1 is a disc
  -- when rotating around its center, the disc has radius equal to rectangle half-diagonal
  -- when rotating around an excentered pivot, the disc has a bigger radius, equal to
  --  the biggest distance between the pivot and any corner of the rectangle
  --  i.e. the magnitude of a vector of width: the biggest horizontal distance between pivot and rectangle left or right
  --                                    height: the biggest vertical distance between pivot and rectangle top or bottom
  -- (if pivot is a corner, it is the full diagonal length)
  -- we need to compute this disc radius so we can properly draw the rotated sprite wherever it will "land" on the screen
  -- (if we just draw on the rectangle area where the sprite originally is, we observe rectangle clipping)
  local max_dx = max(pivot_x, sw - 1 - pivot_x)  -- actually (pivot_x - 0, sw - 1 - pivot_x) i.e. max horizontal distance from pivot to corner
  local max_dy = max(pivot_y, sh - 1 - pivot_y)  -- actually (pivot_y - 0, sh - 1 - pivot_y) i.e. max vertical distance from pivot to corner
  local max_sqr_dist = max_dx * max_dx + max_dy * max_dy
  local max_dist = sqrt(max_sqr_dist)

  -- locate the edges of the target disc's bounding box
  local left = pivot_x - max_dist
  local right = pivot_x + max_dist
  local top = pivot_y - max_dist
  local down = pivot_y + max_dist

  -- backward rendering: cover the whole target disc,
  --  and determine which pixel of the source sprite should be represented
  -- it's not trivial to iterate over a disc (you'd need trigonometry)
  --  so instead, iterate over the target disc's bounding box
  for ix = left, right do
    for iy = top, down do
      local dx = ix - pivot_x
      local dy = iy - pivot_y
      -- we know that nothing should be drawn outside the target disc contained in the bounding box
      -- so only consider pixels inside the target disc
      if dx * dx + dy * dy <= max_sqr_dist then
        -- prepare flip factors
        local sign_x = flip_x and -1 or 1
        local sign_y = flip_y and -1 or 1
        -- compute pixel location on source sprite in spritesheet
        -- this basically a reverse rotation matrix to find which pixel
        --  on the original sprite should be represented

        -- Known issue: luamin will remove brackets from expression a + b * (c + d)
        -- so make sure to store b * (c + d) in an intermediate variable
        -- https://github.com/mathiasbynens/luamin/issues/50
        local rotated_dx = sign_x * ( ca * dx + sa * dy)
        local rotated_dy = sign_y * (-sa * dx + ca * dy)
        local xx = flr(pivot_x + rotated_dx)
        local yy = flr(pivot_y + rotated_dy)

        -- make sure to never draw pixels from the spritesheet
        --  that are outside the source sprite
        -- simply check if the source pixel is located in the source sprite rectangle
        if xx >= 0 and xx < sw and yy >= 0 and yy < sh then
          -- get source pixel
          local c = sget(sx + xx, sy + yy)
          -- ignore if transparent color
          if c ~= transparent_color then
            -- set target pixel color to source pixel color
            pset(x + ix, y + iy, c)
          end
        end
      end
    end
  end
end
