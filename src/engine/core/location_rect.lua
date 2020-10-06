-- location_rect struct: representation of a rectangle containing tiles,
--  defined by its integer inclusive boundaries
local location_rect = new_struct()

-- left      int     i coordinate of top-left tile contained in this rect
-- top       int     j coordinate of top-left tile contained in this rect
-- right     int     i coordinate of bottom-right tile contained in this rect
-- bottom    int     j coordinate of bottom-right tile contained in this rect
function location_rect:init(left, top, right, bottom)
  self.left = left
  self.top = top
  self.right = right
  self.bottom = bottom
end

--#if tostring
function location_rect:_tostring()
  return "location_rect("..joinstr(', ', self.left, self.top, self.right, self.bottom)..")"
end
--#endif

-- return true iff tile location is inside this rectangle
function location_rect:contains(tile_loc)
  return self.left <= tile_loc.i and tile_loc.i <= self.right and
    self.top <= tile_loc.j and tile_loc.j <= self.bottom
end

return location_rect
