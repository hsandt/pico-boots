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
function vector:mirror_y(mirror_y)
  self.y = -self.y
end
