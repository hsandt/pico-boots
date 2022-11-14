require("engine/core/string_join")  -- already in engine/common, but added for clarity

local font_helper = {}

-- replace each character in "text" with the same character preceded by
--  character width adjustment code "\^x[width including space]" following char_width_table (includes space)
--  and default_char_width (includes space) for undefined entries
--  (unless the last code already set the same width) and return the new string
-- note that default_char_width should match the default char width for standard characters
--  (native one for native font, or custom one for custom font) since we don't use custom code for
--  the first characters if they already have the default char width (i.e. they are not keys in char_width_table)
-- text must not contain codes yet as there is no check to skip them
function font_helper.adjust_char_width(text, char_width_table, default_char_width)
  local adjusted_text = ""

  -- consider that we start at default char width
  local last_char_width = default_char_width

  for i=1,#text do
    local c = sub(text,i,i)

    -- text must not contain codes yet, so no need to check for them

    -- check if character uses non-default width, else consider default_char_width
    local width = char_width_table[c] or default_char_width

    -- check if we are already in this width of if it changed since beginning (default) or last code
    if width ~= last_char_width then
      -- width changed, we need to indicate width with code

      -- Note that native Lua doesn't support \ followed by non-hexadecimal value,
      --  but \^ is the same as |6 (you can check this with ord() or == in PICO-8),
      --  so the line below, valid in PICO-8:
      -- adjusted_text = adjusted_text.."\^x"..width
      --  becomes this line working with both PICO-8 and native Lua:
      adjusted_text = adjusted_text.."\6x"..width

      -- The line above is equivalent to the following in PICO-8:

      -- update last char width
      last_char_width = width
    end

    -- always add adjusted text
    adjusted_text = adjusted_text..c
  end

  return adjusted_text
end

-- adjust character width using adjust_char_width, and prepend the custom font code "\14" on start
--  and *every new line*, and return the new string
function font_helper.to_custom_font_with_adjusted_char_width(text, char_width_table, default_char_width)
  local adjusted_text = font_helper.adjust_char_width(text, char_width_table, default_char_width)
  local lines = split(adjusted_text, "\n", false)
  local transformed_lines = transform(lines, function (l)
    return "\14"..l
  end)
  return joinstr_table("\n", transformed_lines)
end

return font_helper
