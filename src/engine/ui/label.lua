-- label struct: container for a text to draw at a given position
local label = new_struct()

-- text      printable    text content to draw (mainly string or number)
-- position  vector       position to draw the label at
-- colour    colors       color index to draw the label with
-- colour    (colors|-1)  color index to draw the label outline with. If -1, no outline is drawn
function label:init(text, position, colour, outline_colour)
  self.text = text
  self.position = position
  self.colour = colour
  self.outline_colour = outline_colour or -1  -- -1 is better than nil for copy_assign
end

--#if tostring
function label:_tostring()
  local outline_colour_string = self.outline_colour >= 0 and color_tostring(self.outline_colour) or "none"
  return "label('"..self.text.."' @ "..self.position.." in "..color_tostring(self.colour).." outlined "..outline_colour_string..")"
end
--#endif

function label:draw()
  if self.outline_colour >= 0 then
    -- draw outline with 4 shadows of offset 1 in every cardinal direction
    -- the trick to avoid 4 separate calls is to mentally rotate the shape by 45 degrees,
    --  so the 4 offsets are the 4 corners of a square
    -- cross iterate on those diagonals offsets known as du and dv, then use a rotation matrix
    --  + scaling to come back to dx and dy as -1, 0 or +1
    for du = -1, 1, 2 do
      for dv = -1, 1, 2 do
        local dx = (du + dv) / 2
        local dy = (du - dv) / 2
        api.print(self.text, self.position.x + dx, self.position.y + dy, self.outline_colour)
      end
    end
  end
  api.print(self.text, self.position.x, self.position.y, self.colour)
end

return label
