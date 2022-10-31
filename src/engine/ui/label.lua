local text_helper = require("engine/ui/text_helper")

-- Label struct: container for a text to draw at a given position
-- Implements drawable:
local label = new_struct()

-- text             printable    text content to draw (mainly string or number)
-- position         vector       position to draw the label at
-- alignment        alignments   text alignment
-- colour           colors       color index to draw the label with
-- outline_colour   (colors|-1)  color index to draw the label outline with. If -1, no outline is drawn
-- use_custom_font  bool         if true, the custom font dimensions are used for alignment
--                               if you use custom font via poke(0x5f58,0x81) or string prefix "\14",
--                               this should be true
function label:init(text, position, alignment, colour, outline_colour, use_custom_font)
  assert(text)
  self.text = text
  self.position = position
  self.alignment = alignment
  self.colour = colour
  self.outline_colour = outline_colour or -1  -- -1 is better than nil for copy_assign
  self.use_custom_font = use_custom_font
end

--#if tostring
function label:_tostring()
  local outline_colour_string = self.outline_colour >= 0 and color_tostring(self.outline_colour) or "none"
  local use_custom_font_string = self.use_custom_font and "yes" or "no"
  return "label('"..self.text.."' @ "..self.position.." aligned "..self.alignment.." in "..color_tostring(self.colour).." outlined "..outline_colour_string..", custom font: "..use_custom_font_string..")"
end
--#endif

function label:draw()
  -- be careful, as label struct prefers POD outline_colour of -1 for no outline,
  --  while print_with_outline will check for falsy values for no outline
  -- `or nil` is optional since false is also falsy, but clearer
  text_helper.print_aligned(self.text, self.position.x, self.position.y, self.alignment,
    self.colour, self.outline_colour >= 0 and self.outline_colour or nil, self.use_custom_font)
end

return label
