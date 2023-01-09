-- exceptionally a global require
-- make sure to require it in your common_game.lua too if using minify lv3
-- for early definition (if using unify, redundant require will be removed)
require("engine/core/string_split")
local outline = require("engine/ui/outline")

local text_helper = {}

-- https://pastebin.com/NS8rxMwH
-- converted to clean lua, adapted coding style
-- changed behavior:
-- - avoid adding next line if first word of line is too long
-- - don't add trailing space at end of line
-- - don't add eol at the end of the last line
-- - count the extra separator before next word in the line length prediction test
-- I kept the fact that we don't collapse spaces so 2x, 3x spaces are preserved
-- as a side effect, \n just at the end of a wrapped line will produce a double newline,
--  so depending on your design, you may want not to add an extra \n if there is already one

-- word wrap (string, char width)
function text_helper.wwrap(s,w)
  local retstr = ''
  local lines = split(s, '\n', --[[convert_numbers:]] false)
  local nb_lines = count(lines)

  for i = 1, nb_lines do
    local linelen = 0
    local words = split(lines[i], ' ', --[[convert_numbers:]] false)
    local nb_words = count(words)

    for k = 1, nb_words do
      local wrd = words[k]
      local should_wrap = false

      if k > 1 then
        -- predict length after adding 1 separator + next word
        if linelen + 1 + #wrd > w then
          -- wrap
          retstr = retstr..'\n'
          linelen = 0
          should_wrap = true
        else
          -- don't wrap, so add space after previous word if not the first one
          retstr = retstr..' '
          linelen = linelen + 1
        end
      end

      retstr = retstr..wrd
      linelen = linelen + #wrd
    end

    -- wrap following \n already there
    if i < nb_lines then
      retstr = retstr..'\n'
    end
  end

  return retstr
end

-- return the width of a single-line text
-- if use_custom_font is true, use the width stored in custom font memory
-- we only use width, not width 2, so char >= 128 are not supported
-- see font_snippet.lua for more info
function text_helper.compute_single_line_text_width(single_line_text, use_custom_font)
  -- standard character width or custom font "width 1" for characters between \32 and \127
  -- it can be overridden by control codes
  local default_char_width = use_custom_font and peek(0x5600) or character_width

  -- wide character width or custom font "width 2" for characters from \128
  -- it can be overridden by control codes (according to
  --  https://pico-8.fandom.com/wiki/P8SCII_Control_Codes > Setting the character size (cursor advance rate),
  --  it then becomes the override char width + 4)
  local default_wide_char_width = use_custom_font and peek(0x5601) or wide_character_width

  -- precompute difference standard-wide width, since when overriding char width, we preserve it
  local wide_character_width_extra = default_wide_char_width - default_char_width

  -- we start at default char widths until we meet an override control code
  local current_char_width = default_char_width
  local current_wide_char_width = default_wide_char_width

  local total_width = 0

  -- iterate on every character of the string

  -- we must declare index before while loop so we can skip characters by incrementing it
  --  manually when reaching control codes (in a for loop, index would be a mere copy and
  --  incrementing it inside the loop would not affect iterations)
  local i = 1

  while i <= #single_line_text do
    local c = sub(single_line_text, i, i)

    -- to make comparisons easier, we use the ordinal
    -- we could also compare c directly with characters via code "\xx" or chr(xx)
    -- however in the case of "\128", picotool turns it into "_" which gives incorrect results,
    --  so we must either compare c to chr(128) or compare c_ord to 128
    local c_ord = ord(c)

    -- check width of current character
    local width

    if c_ord < 32 then
      -- control character
      -- we only support \14 which takes no width
      width = 0

--#if assert
      if c_ord == 14 then
        -- this is the control character to enable custom font, so ignore it for width
        assert(use_custom_font, "text_helper.compute_single_line_text_width: single_line_text '"..
          single_line_text.."' contains control character \\14 to enable custom font at position "..i..", but "..
          "use_custom_font is false, so the width may be incorrect")
      -- apart from 14, we add other control codes to support little by little as needed:
      elseif c_ord == 6 then
        -- \6 is like \^ which is used for special commands
        -- for now, we support:
        -- - \^x[1 hex digit] to override character width from this point
        if #single_line_text >= i + 1 then
          local special_command_char = sub(single_line_text, i + 1, i + 1)
          if special_command_char == "x" then
            if #single_line_text >= i + 2 then
              local override_char_width_hex = sub(single_line_text, i + 2, i + 2)
              if "0" <= override_char_width_hex and override_char_width_hex <= "9" or
                  "a" <= override_char_width_hex and override_char_width_hex <= "f" then
                -- skip the next two characters: x + hex digit
                i = i + 2

                current_char_width = tonum("0x"..override_char_width_hex)
                current_wide_char_width = current_char_width + wide_character_width_extra
              else
                assert(false, "text_helper.compute_single_line_text_width: \\^x is followed by "..
                  override_char_width_hex..", expected an hex digit")
              end
            else
              assert(false, "text_helper.compute_single_line_text_width: \\^x needs at least one character "..
                "afterward to define the override char width value")
            end
          else
            assert(false, "text_helper.compute_single_line_text_width: \\^ is followed by "..
              special_command_char..", we only support 'x' at the moment")
          end
        else
          assert(false, "text_helper.compute_single_line_text_width: \\^ needs at least one character "..
            "afterward to define the special command type")
        end
      else
        assert(false, "text_helper.compute_single_line_text_width: single_line_text '"..
          single_line_text.."' contains unsupported control character "..c.." at position "..i)
      end
--#endif
    elseif c_ord < 128 then
      width = current_char_width
    else
      -- from \128, we have wide characters
      width = current_wide_char_width
    end

    -- cumulate total width
    total_width = total_width + width

    -- we are in while loop, so increment index manually
    i = i + 1
  end

  return total_width
end

-- return the height of a character, which is also the height of a single-line of text,
--  including the separator 1px space below
-- if use_custom_font is true, use the height stored in custom font memory
-- see font_snippet.lua for more info
function text_helper.compute_char_height(use_custom_font)
  return use_custom_font and peek(0x5602) or character_height
end

-- return the height of a multiline text, using the number of lines
--  including the separator 1px space below
-- note that empty text is still considered like a single non-empty line
-- if use_custom_font is true, use the height stored in custom font memory
-- see font_snippet.lua for more info
function text_helper.compute_text_height(text, use_custom_font)
  local lines = split(text, '\n', --[[convert_numbers:]] false)
  local char_height = text_helper.compute_char_height(use_custom_font)
  return #lines * char_height
end

-- return the left position where to print some `single_line_text`
--  so it appears x-centered at `center_x`
-- single_line_text: string
-- center_x: vector
-- use_custom_font: bool
function text_helper.single_line_center_x_to_left(single_line_text, center_x, use_custom_font)
  -- Subtract text half-width
  -- then re-add 1 on x so the visual x-center of a character is really in the middle
  local single_line_text_width = text_helper.compute_single_line_text_width(single_line_text, use_custom_font)
  return center_x - single_line_text_width / 2 + 1
end

-- return the top position where to print some single line text (not passed, since only
--  the line height matters) so it appears y-centered at `center_y`
-- center_y: vector
-- use_custom_font: bool
function text_helper.single_line_center_y_to_top(center_y, use_custom_font)
  -- Subtract text half-height
  -- then re-add 1 on y so the visual center of a character is really in the middle
  local char_height = text_helper.compute_char_height(use_custom_font)
  return center_y - char_height / 2 + 1
end

-- return the top-left position where to print some `single_line_text`
--  so it appears centered at (`center_x`, `center_y`)
-- single_line_text: string
-- center_x: float
-- center_y: float
-- use_custom_font: bool
function text_helper.single_line_center_to_topleft(single_line_text, center_x, center_y, use_custom_font)
  return text_helper.single_line_center_x_to_left(single_line_text, center_x, use_custom_font), text_helper.single_line_center_y_to_top(center_y, use_custom_font)
end

-- print `text` at `x`, `y` with the given alignment, color `col` and
--  outline color `outline_col`
-- multi-line text is supported, and will be vertically aligned as a whole if alignments
--  is center
-- text: string
-- x: float
-- y: float
-- aligment: alignments
-- col: colors
-- outline_col: colors | nil
-- use_custom_font: if true, use size of custom font character
-- extra_line_spacing: if set, add it to the computed character height (which already includes 1px space)
--                     if you use an outline, it is recommended to pass at least 1, as the outline is not taken
--                     into account to compute character height
function text_helper.print_aligned(text, x, y, alignment, col, outline_color, use_custom_font, extra_line_spacing)
  extra_line_spacing = extra_line_spacing or 0

  -- we are doing a job similar to compute_text_height's job, but since we need to lines below,
  -- we cannot just call it, so we prefer doing the split + compute_char_height ourselves
  local lines = split(text, '\n', --[[convert_numbers:]] false)

  local char_height = text_helper.compute_char_height(use_custom_font)

  -- check for vertical alignment (currently, only center does it)
  if alignment == alignments.center then
    -- center on y too, by subtracting half of line height for extra line
    y = y - (#lines - 1) * char_height / 2
  end

  for single_line_text in all(lines) do
    -- compute x and y for this line based on alignment and font
    local line_x, line_y

    if alignment == alignments.center then
      line_x, line_y = text_helper.single_line_center_to_topleft(single_line_text, x, y, use_custom_font)
    elseif alignment == alignments.horizontal_center then
      line_x = text_helper.single_line_center_x_to_left(single_line_text, x, use_custom_font)
      line_y = y
    elseif alignment == alignments.right then
      -- user passed position of right edge of single_line_text,
      -- so go to the left by single_line_text length, +1 since there an extra 1px interval
      line_x = x - text_helper.compute_single_line_text_width(single_line_text, use_custom_font) + 1
      line_y = y
    else
      line_x, line_y = x, y
    end

    -- print with outline at this position
    outline.print_with_outline(single_line_text, line_x, line_y, col, outline_color)

    -- prepare offset for next line
    y = y + char_height + extra_line_spacing
  end
end

return text_helper
