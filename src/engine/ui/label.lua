local outline = require("engine/ui/outline")

-- Label struct: container for a text to draw at a given position
-- Implements drawable:
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
  -- be careful, as label struct prefers POD outline_colour of -1 for no outline,
  --  while print_with_outline will check for falsy values for no outline
  -- `or nil` is optional since false is also falsy, but clearer
  outline.print_with_outline(self.text, self.position.x, self.position.y,
    self.colour, self.outline_colour >= 0 and self.outline_colour or nil)
end

return label
