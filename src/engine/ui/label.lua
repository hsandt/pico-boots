local text_helper = require("engine/ui/text_helper")

-- Label struct: container for a text to draw at a given position
-- Implements drawable:
local label = new_struct()

-- text             printable    text content to draw (mainly string or number)
-- position         vector       position to draw the label at
-- alignment        alignments   text alignment
-- colour           colors       color index to draw the label with
-- outline_colour   (colors|-1)  color index to draw the label outline with. If -1, no outline is drawn
function label:init(text, position, alignment, colour, outline_colour, override_char_width, override_char_height)
  assert(text)
  self.text = text
  self.position = position
  self.alignment = alignment
  self.colour = colour
  self.outline_colour = outline_colour or -1  -- -1 is better than nil for copy_assign
end

--#if tostring
function label:_tostring()
  local outline_colour_string = self.outline_colour >= 0 and color_tostring(self.outline_colour) or "none"
  return "label('"..self.text.."' @ "..self.position.." aligned "..self.alignment.." in "..color_tostring(self.colour).." outlined "..outline_colour_string..")"
end
--#endif

function label:draw()
  -- be careful, as label struct prefers POD outline_colour of -1 for no outline,
  --  while print_with_outline will check for falsy values for no outline
  -- `or nil` is optional since false is also falsy, but clearer
  text_helper.print_aligned(self.text, self.position.x, self.position.y, self.alignment,
    self.colour, self.outline_colour >= 0 and self.outline_colour or nil)
end

return label
