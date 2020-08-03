function vector.unit_from_angle(angle)
  return vector(cos(angle), sin(angle))
end

function vector:dot(other)
  return self.x * other.x + self.y * other.y
end

function vector:sqr_magnitude()
  return self:dot(self)
end

function vector:magnitude()
  return sqrt(self:sqr_magnitude())
end

-- return a normalized vector is non-zero, else a zero vector
function vector:normalized()
  local magnitude = self:magnitude()
  -- make sure to return vector.zero() if magnitude is zero, not self,
  -- even if both have the same content, because the returned self reference
  -- may be used to modify self's content, and this function should be "const"
  return magnitude > 0 and self / magnitude or vector.zero()
end

-- normalize vector in-place
function vector:normalize()
  self:copy_assign(self:normalized())
end

-- return copy of vector with magnitude clamped by max_magnitude
function vector:with_clamped_magnitude(max_magnitude)
  assert(max_magnitude >= 0)
  local magnitude = self:magnitude()
  return magnitude > max_magnitude and max_magnitude / magnitude * self or self:copy()
end

-- clamp magnitude in-place
function vector:clamp_magnitude(max_magnitude)
  -- a small waste if vector does not need clamping as we create a temporary copy
  -- for nothing, but OK
  self:copy_assign(self:with_clamped_magnitude(max_magnitude))
end

-- return copy of vector with magnitude clamped by max_magnitude in cardinal directions
function vector:with_clamped_magnitude_cardinal(max_magnitude_x, max_magnitude_y)
  -- if 1 arg is passed, use the same max for x and y
  max_magnitude_y = max_magnitude_y or max_magnitude_x
  assert(max_magnitude_x >= 0 and max_magnitude_y >= 0)
  return vector(mid(-max_magnitude_x, self.x, max_magnitude_x), mid(-max_magnitude_y, self.y, max_magnitude_y))
end

-- clamp magnitude in cardinal directions in-place
function vector:clamp_magnitude_cardinal(max_magnitude_x, max_magnitude_y)
  self:copy_assign(self:with_clamped_magnitude_cardinal(max_magnitude_x, max_magnitude_y))
end

-- return copy of vector mirrored horizontally
function vector:mirrored_x()
  return vector(-self.x, self.y)
end

-- mirror the vector horizontally in-place
function vector:mirror_x()
  self.x = -self.x
end

-- return copy of vector mirrored horizontally
function vector:mirrored_y()
  return vector(self.x, -self.y)
end

-- mirror the vector vertically in-place
function vector:mirror_y()
  self.y = -self.y
end

-- return copy of vector rotated by 90 degrees clockwise (for top-left origin)
function vector:rotated_90_cw()
  return vector(-self.y, self.x)
end

-- rotate vector by 90 degrees clockwise in-place
function vector:rotate_90_cw_inplace()
  self:copy_assign(self:rotated_90_cw())
end

-- return copy of vector rotated by 90 degrees counter-clockwise (for top-left origin)
function vector:rotated_90_ccw()
  return vector(self.y, -self.x)
end

-- rotate by 90 degrees counter-clockwise in-place
function vector:rotate_90_ccw_inplace()
  self:copy_assign(self:rotated_90_ccw())
end
