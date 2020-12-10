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
