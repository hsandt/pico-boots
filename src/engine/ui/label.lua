require("engine/render/color")

-- label struct: container for a text to draw at a given position
local label = new_struct()

-- text      printable  text content to draw (mainly string or number)
-- position  vector     position to draw the label at
-- colour    int        color index to draw the label with
function label:_init(text, position, colour)
  self.text = text
  self.position = position
  self.colour = colour
end

--#if log
function label:_tostring()
  return "label('"..self.text.."' @ "..self.position.." in "..color_tostring(self.colour)..")"
end
--#endif

function label:draw()
  api.print(self.text, self.position.x, self.position.y, self.colour)
end

return label
