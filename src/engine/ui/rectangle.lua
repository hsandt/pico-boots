-- rectangle struct: a drawable shape for a filled rectangle
-- Implements drawable: position member, draw method
local rectangle = new_struct()

-- position  vector       top-left position to draw the rectangle at
-- width     int          rectangle width (minimum 1, 1 for a vertical line)
-- height    int          rectangle height (minimum 1, 1 for a horizontal line)
-- colour    colors       color index to draw the rectangle with
function rectangle:init(position, width, height, colour)
  self.position = position
  self.width = width
  self.height = height
  self.colour = colour
end

--#if tostring
function rectangle:_tostring()
  return "rectangle(@ "..self.position..", width: "..self.width..", height: "..self.height..", "..color_tostring(self.colour)..")"
end
--#endif

function rectangle:draw()
  -- make sure to subtract 1 so width/height is the actual width/height including edge pixels
  rectfill(self.position.x, self.position.y, self.position.x + self.width - 1, self.position.y + self.height - 1,
    self.colour)
end

return rectangle
