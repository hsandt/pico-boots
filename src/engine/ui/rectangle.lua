-- rectangle struct: a drawable shape for a filled rectangle
-- it is a drawable, and must implement a draw method
local rectangle = new_struct()

-- position  vector       top-left position to draw the rectangle at
-- width     int          rectangle width
-- height    int          rectangle height
-- colour    colors       color index to draw the rectangle with
function rectangle:init(position, width, height, colour)
  self.position = position
  self.width = width
  self.height = height
  self.colour = colour
end

function rectangle:draw()
  rectfill(self.position.x, self.position.y, self.position.x + self.width, self.position.y + self.height,
    self.colour)
end

return rectangle
