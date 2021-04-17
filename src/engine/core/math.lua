-- math constants

huge = 1/0  -- aka `inf`, appears at 32768 in PICO-8, actually 0x7fff.ffff rounded as max integer is 32767
-- use -huge for `-inf`, appears as -32768 in PICO-8, actually -0x7fff.ffff == 0x8000.0001 rounded

-- numeric helpers

--#if itest
function almost_eq(lhs, rhs, eps)
  eps = eps or 0.01
  assert(lhs, "lhs is nil")
  assert(rhs, "rhs")
  if type(lhs) == "number" and type(rhs) == "number" then
    return abs(lhs - rhs) <= eps
  elseif lhs.almost_eq then
    return lhs:almost_eq(rhs, eps)
--#if assert
  else
    assert(false, "almost_eq cannot compare "..lhs.." and "..rhs)
--#endif
  end
end
--#endif

-- unfortunately // only works with native Lua
--  and \ only works with PICO-8 but picotool doesn't accept it
-- so we use our own function for integer division (you can always post-process it back
--  to \ if you want)
function int_div(a, b)
  return flr(a/b)
end

-- geometry/data grid helpers
-- (defined from dependee to dependent so luamin -G recognizes assigned globals
--  for later usage)

-- vector struct: a pair of pixel coordinates (x, y) that represents a 2d vector
-- in the space (position, displacement, speed, acceleration...)
vector = new_struct()

-- x       int     horizontal coordinate in pixels
-- y       int     vertical   coordinate in pixels
function vector:init(x, y)
  self.x = x
  self.y = y
end

function vector.__eq(lhs, rhs)
  -- very lightweight, as commented in location.__eq expect failure
  --  when comparing non-vectors, not returning false
  --  (even harsher as it will also fail with tables because of is_zero)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.__eq: lhs and rhs are not both a vector (lhs: "..nice_dump(lhs)..", rhs: "..nice_dump(rhs)..")")
  return vector.is_zero(lhs - rhs)
end

--#if itest
-- almost_eq can be used as static function of method, since self would simply replace lhs
function vector.almost_eq(lhs, rhs, eps)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.almost_eq: lhs and rhs are not both vectors (lhs: "..nice_dump(lhs)..", rhs: "..nice_dump(rhs)..")")
  return almost_eq(lhs.x, rhs.x, eps) and almost_eq(lhs.y, rhs.y, eps)
end
--#endif


--#if tostring
function vector:_tostring()
  return "vector("..self.x..", "..self.y..")"
end
--#endif

-- return coordinate matching `coord` string ("x" or "y")
-- assert if `coord` is not "x" nor "y"
function vector:get(coord)
  assert(coord == "x" or coord == "y", "vector:get: coord must be 'x' or 'y'")
  return coord == "x" and self.x or self.y
end

-- set coordinate matching `coord` string ("x" or "y")
-- assert if `coord` is not "x" nor "y"
function vector:set(coord, value)
  assert(coord == "x" or coord == "y", "vector:set: coord must be 'x' or 'y'")
  if coord == "x" then
    self.x = value
  else
    self.y = value
  end
end

function vector.__add(lhs, rhs)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.__add: lhs and rhs are not both vectors (lhs: "..nice_dump(lhs)..", rhs: "..nice_dump(rhs)..")")
  return vector(lhs.x + rhs.x, lhs.y + rhs.y)
end

-- in-place operation as native lua replacements for pico-8 +=
function vector:add_inplace(other)
  self:copy_assign(self + other)
end

function vector.__sub(lhs, rhs)
  assert(getmetatable(lhs) == vector and getmetatable(rhs) == vector, "vector.__sub: lhs and rhs are not both vectors (lhs: "..nice_dump(lhs)..", rhs: "..nice_dump(rhs)..")")
  return lhs + (-rhs)
end

-- in-place operation as native lua replacements for pico-8 -=
function vector:sub_inplace(other)
  self:copy_assign(self - other)
end

function vector.__unm(v)
  return -1 * v
end

function vector.__mul(lhs, rhs)
--#if assert
      assert(type(lhs) == "number" or type(rhs) == "number", "vector multiplication is only supported with a scalar, "..
        "tried to multiply "..stringify(lhs).." and "..stringify(rhs))
--#endif
  -- Assuming one of the arguments is a number, we only need to check if the other is
  -- a vector. To reduce tokens further, we only check for a metatable.
  -- This should be equivalent to checking if type(lhs) == "number"
  if getmetatable(rhs) then
    return vector(lhs * rhs.x, lhs * rhs.y)
  else
    return rhs * lhs
  end
end

-- in-place operation as native lua replacements for pico-8 *=
function vector:mul_inplace(number)
  self:copy_assign(self * number)
end

function vector.__div(lhs, rhs)
--#if assert
    assert(type(rhs) == "number", "vector division is only supported with a scalar as rhs, "..
      "tried to multiply "..stringify(lhs).." and "..rhs)
    assert(rhs ~= 0, "cannot divide vector "..lhs:_tostring().." by zero")
--#endif
  return lhs * (1/rhs)
end

-- in-place operation as native lua replacements for pico-8 /=
function vector:div_inplace(number)
  self:copy_assign(self / number)
end

-- dot product
-- it's a bit advanced for this module and used to be in vector_ext,
--  but allows to compute sqr_magnitude => is_zero => __eq and I'd rather
--  have __eq defined in math than an extension (to avoid core semantic
--  change when requiring new extension)
function vector:dot(other)
  return self.x * other.x + self.y * other.y
end

-- return square magnitude
function vector:sqr_magnitude()
  return self:dot(self)
end

-- return true iff vector has 0 components
function vector:is_zero()
  -- more calculation than comparing members to 0 but fewer tokens
  return self:sqr_magnitude() == 0
end

function vector.zero()
  return vector(0, 0)
end

-- tile_vector struct: a pair of integer coords (i, j) that represents a position
-- on either a spritesheet or a tilemap of 8x8 squares (8 is the "tile size")
-- for sprite locations and tilemap locations, use sprite_id_location and location resp.
-- for sprite span (sprite size on the spritesheet), use tile_vector directly
tile_vector = new_struct()

-- i       int     horizontal coordinate in tile size
-- j       int     vertical   coordinate in tile size
function tile_vector:init(i, j)
  self.i = i
  self.j = j
end

--#if tostring
function tile_vector:_tostring()
  return "tile_vector("..self.i..", "..self.j..")"
end
--#endif

-- return the topleft position corresponding to a tile location
function tile_vector:to_topleft_position()
  return vector(8 * self.i, 8 * self.j)
end

-- sprite location is a special tile_vector with the semantics of a spritesheet location
-- and associated conversion methods
sprite_id_location = derived_struct(tile_vector)

--#if tostring
function sprite_id_location:_tostring()
  return "sprite_id_location("..self.i..", "..self.j..")"
end
--#endif

-- return the sprite id corresponding to a sprite location on a spritesheet
function sprite_id_location:to_sprite_id()
  return 16 * self.j + self.i
end

-- return the sprite id location corresponding to a sprite id
function sprite_id_location.from_sprite_id(n)
  return sprite_id_location(n % 16, int_div(n, 16))
end

-- location is a special tile_vector with the semantics of a tilemap location
-- and associated conversion methods
location = derived_struct(tile_vector)

-- custom equality, defined as useful in tilemap algorithms
function location.__eq(lhs, rhs)
  -- very lightweight, we don't check for metatable on release
  -- comparison with an unrelated type will fail with assert in debug,
  --  and either return false (if the other type is a table)
  --  or fail on invalid indexing (if the other type is something else)
  -- this is not Lua standard (where default equality compares by ref and at least returns false)
  --  but this is not worse than C (which would not compile on invalid comparison)
  -- just make sure you always compare struct of the same type, and if using unittest_helper's
  --  are_same, that you do not `use_mt_equality` unless you are sure the comparison will be valid
  assert(getmetatable(lhs) == location and getmetatable(rhs) == location, "location.__eq: lhs and rhs are not both a location (lhs: "..nice_dump(lhs)..", rhs: "..nice_dump(rhs)..")")
  return lhs.i == rhs.i and lhs.j == rhs.j
end

--#if tostring
function location:_tostring()
  return "location("..self.i..", "..self.j..")"
end
--#endif

-- return the center position corresponding to a tile location
function location:to_center_position()
  return vector(8 * self.i + 4, 8 * self.j + 4)
end

-- sum two tile_vector / location values
-- we don't mind summing 2 locations even though technically incorrect, because in frame change
--  we often add or subtract origin coordinates which tend to be location and not tile_vector in code
function location.__add(lhs, rhs)
  assert((getmetatable(lhs) == location or getmetatable(lhs) == tile_vector) and (getmetatable(rhs) == location or getmetatable(rhs) == tile_vector), "location.__add: lhs and rhs are not a location or a tile_vector (lhs: "..nice_dump(lhs)..", rhs: "..nice_dump(rhs)..")")
  return location(lhs.i + rhs.i, lhs.j + rhs.j)
end

-- compute difference between two locations
function location.__sub(lhs, rhs)
  assert((getmetatable(lhs) == location or getmetatable(lhs) == tile_vector) and (getmetatable(rhs) == location or getmetatable(rhs) == tile_vector), "location.__sub: lhs and rhs are not a location or a tile_vector (lhs: "..nice_dump(lhs)..", rhs: "..nice_dump(rhs)..")")
  return location(lhs.i - rhs.i, lhs.j - rhs.j)
end

-- exceptionally defined after location to allow luamin -G to recognize location as
--  an assigned global var at this point, without having to add location = nil at the top
-- return the tile location containing this vector position (non-injective)
function vector:to_location()
  return location(flr(self.x / tile_size), flr(self.y / tile_size))
end

-- enums data

directions = {
  left = 0,
  up = 1,
  right = 2,
  down = 3
}

dir_vectors = {
  [0] = vector(-1, 0),
  vector(0, -1),
  vector(1, 0),
  vector(0, 1)
}

horizontal_dirs = {
  left = 1,
  right = 2
}

vertical_dirs = {
  up = 1,
  down = 2
}

horizontal_dir_vectors = {
  vector(-1, 0),  -- to left
  vector(1, 0)    -- to right
}

horizontal_dir_signs = {
  -1,               -- left sign
  1                 -- right sign
}

-- return left if signed speed is negative, right if positive. ub unless signed speed is not 0
function signed_speed_to_dir(signed_speed)
  assert(signed_speed ~= 0)
  return signed_speed < 0 and horizontal_dirs.left or horizontal_dirs.right
end

-- return opposite direction: left <-> right and up <-> down
function oppose_dir(direction)
  return (direction + 2) % 4
end
