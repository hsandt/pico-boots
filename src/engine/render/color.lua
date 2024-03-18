-- default pico-8 colors

colors = {
  black = 0,
  dark_blue = 1,
  dark_purple = 2,
  dark_green = 3,
  brown = 4,
  dark_gray = 5,
  light_gray = 6,
  white = 7,
  red = 8,
  orange = 9,
  yellow = 10,
  green = 11,
  blue = 12,
  indigo = 13,
  pink = 14,
  peach = 15
}

--#if tostring
-- this is literally invert_table(colors)
--  we may redefine it as such (but make sure to define invert_table if #tostring)
--  for now we keep it because colors table may disappear if we replace enum members
--  with their integer values during preprocessing
color_strings = {
  [0] = "black",
  "dark_blue",
  "dark_purple",
  "dark_green",
  "brown",
  "dark_gray",
  "light_gray",
  "white",
  "red",
  "orange",
  "yellow",
  "green",
  "blue",
  "indigo",
  "pink",
  "peach"
}

function color_tostring(colour)
  return colour and (color_strings[colour % 16] or "invalid color") or "nil"
end
--#endif

function color_to_bitmask(c)
  -- transparency color bitmasks used by palt are low-endian, so use complementary 0-based index
  return 1 << 15 - c
end

-- return a transparent color mask corresponding to passed transparent_color_arg
-- if transparent_color_arg is a sequence of color integers, generate a mask from them
-- if transparent_color_arg is a single color integer, generate a mask for it
-- if transparent_color_arg is nil, generate a mask for black (default)
function generic_transparent_color_arg_to_mask(transparent_color_arg)
  if type(transparent_color_arg) == "table" then
    -- expecting a sequence of color indices
    local transparent_color_bitmask = 0

    for c in all(transparent_color_arg) do
      -- use shl instead of << just so picotool doesn't fail
      transparent_color_bitmask = transparent_color_bitmask + color_to_bitmask(c)
    end

    return transparent_color_bitmask
  elseif transparent_color_arg then
    -- expecting a single color index
    return color_to_bitmask(transparent_color_arg)
  else  -- falsey, generally nil
    return color_to_bitmask(colors.black)
  end
end

-- set colour as the only transparent color
function set_unique_transparency(colour)
  -- reset any previous transparency change
  palt()
  -- default color (black) is not transparent anymore
  palt(0, false)
  -- new transparency
  palt(colour, true)
end

-- swap table of original colors with table of new colors
function swap_colors(original_colors, new_colors)
  assert(#original_colors == #new_colors, "original colors and new colors sequence lenghts don't match: "..#original_colors.." vs "..#new_colors)
  for i = 1, #original_colors do
    pal(original_colors[i], new_colors[i])
  end
end
