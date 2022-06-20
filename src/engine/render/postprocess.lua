-- postprocessing object
-- usage:
-- 1. create a postprocess instance in your gamestate init, store it as member
-- 2. (optional) set persistent parameters:
--    bool use_blue_tint: if true, only go through blue tones of colors when going dark
--                        if false, use the default purple/brown shades
-- 3. after the end of your gamestate render, call postprocess:apply()
-- 4. change parameters during your animation sequences:
--    int darkness: level of darkness, from 0 (no change) to 5 (pitch black)
local postprocess = new_class()

-- darkness swap palette
-- each color is associated to 6 levels of darkness
-- 0 is not represented, we just don't swap colors (handle this case manually if needed)
-- 5 is not represented, we just clear screen (pitch black)
-- we skip black as initial color as it doesn't get darker, so we can start at index 1 and we don't need
--  explicit keys at all
postprocess.swap_palette_by_darkness = {
  --   [colors.black] =                {colors.black, ...},
  --[[ [colors.dark_blue] = ]]         {colors.dark_blue,   colors.dark_blue,   colors.black,       colors.black},
  --[[ [colors.dark_purple] = ]]       {colors.dark_purple, colors.dark_purple, colors.dark_blue,   colors.black},
  --[[ [colors.dark_green] = ]]        {colors.dark_blue,   colors.dark_blue,   colors.black,       colors.black},
  --[[ [colors.brown] = ]]             {colors.dark_purple, colors.dark_purple, colors.dark_gray,   colors.black},
  --[[ [colors.dark_gray] = ]]         {colors.dark_gray,   colors.dark_blue,   colors.dark_blue,   colors.black},
  --[[ [colors.light_gray] = ]]        {colors.indigo,      colors.indigo,      colors.dark_gray,   colors.dark_gray},
  --[[ [colors.white] = ]]             {colors.peach,       colors.light_gray,  colors.brown,       colors.dark_gray},
  --[[ [colors.red] = ]]               {colors.brown,       colors.dark_purple, colors.dark_purple, colors.dark_gray},
  --[[ [colors.orange] = ]]            {colors.brown,       colors.brown,       colors.dark_gray,   colors.dark_gray},
  --[[ [colors.yellow] = ]]            {colors.peach,       colors.orange,      colors.brown,       colors.indigo},
  --[[ [colors.green] = ]]             {colors.dark_green,  colors.dark_green,  colors.dark_blue,   colors.dark_blue},
  --[[ [colors.blue] = ]]              {colors.indigo,      colors.indigo,      colors.dark_blue,   colors.dark_blue},
  --[[ [colors.indigo] = ]]            {colors.dark_purple, colors.dark_purple, colors.dark_blue,   colors.dark_blue},
  --[[ [colors.pink] = ]]              {colors.brown,       colors.brown,       colors.dark_purple, colors.dark_purple},
  --[[ [colors.peach] = ]]             {colors.orange,      colors.brown,       colors.dark_gray,   colors.dark_gray}
}

postprocess.swap_palette_by_darkness_blue_tint = {
  --   [colors.black] =                {colors.black, ...},
  --[[ [colors.dark_blue] = ]]         {colors.dark_blue,   colors.dark_blue,   colors.black,       colors.black},
  --[[ [colors.dark_purple] = ]]       {colors.dark_purple, colors.dark_blue, colors.dark_blue,   colors.black},
  --[[ [colors.dark_green] = ]]        {colors.dark_blue,   colors.dark_blue,   colors.black,       colors.black},
  --[[ [colors.brown] = ]]             {colors.dark_purple, colors.dark_blue, colors.dark_blue,   colors.black},
  --[[ [colors.dark_gray] = ]]         {colors.dark_gray,   colors.dark_blue,   colors.dark_blue,   colors.black},
  --[[ [colors.light_gray] = ]]        {colors.indigo,      colors.indigo,      colors.dark_blue,   colors.dark_blue},
  --[[ [colors.white] = ]]             {colors.light_gray,  colors.indigo,      colors.indigo,      colors.dark_blue},
  --[[ [colors.red] = ]]               {colors.dark_purple,       colors.dark_purple, colors.dark_blue, colors.dark_blue},
  --[[ [colors.orange] = ]]            {colors.brown,       colors.dark_purple,       colors.dark_blue,   colors.dark_blue},
  --[[ [colors.yellow] = ]]            {colors.light_gray,       colors.indigo,      colors.dark_blue,       colors.dark_blue},
  --[[ [colors.green] = ]]             {colors.indigo,  colors.indigo,  colors.dark_blue,   colors.dark_blue},
  --[[ [colors.blue] = ]]              {colors.indigo,      colors.indigo,      colors.dark_blue,   colors.dark_blue},
  --[[ [colors.indigo] = ]]            {colors.indigo,      colors.dark_blue,   colors.dark_blue,   colors.black},
  --[[ [colors.pink] = ]]              {colors.dark_purple,       colors.dark_purple,       colors.dark_blue, colors.dark_blue},
  --[[ [colors.peach] = ]]             {colors.light_gray,      colors.indigo,       colors.dark_blue,   colors.dark_blue}
}

-- darkness    int    darkness level (0: normal palette, 1: darker, 2: very dark, 3: pitch black)
function postprocess:init()
  self.darkness = 0
end

function postprocess:apply()
  if self.darkness == 0 then
    -- post-render palette swap seems to persist even after cls()
    --  so manually reset palette in case nothing else does
    pal()
  elseif self.darkness < 5 then
    local swap_palette = self.use_blue_tint and
      postprocess.swap_palette_by_darkness_blue_tint or
      postprocess.swap_palette_by_darkness
    -- black can't get darker, just check the other 15 colors
    for c = 1, 15 do
      pal(c, swap_palette[c][self.darkness], 1)
    end
  else
    -- everything is black at level 5+, so just clear screen
    cls()
  end
end

--#if debug_menu

-- this method could be used for real game, but apply handles edge cases in its own way,
--  using pal and cls, so it doesn't need it
function postprocess.get_swapped_color(swap_palette, c, darkness)
  if c == colors.black then
    -- black stays black at any darkness level
    return colors.black
  elseif darkness == 0 then
    -- darkness 0 is not indicated in table, always preserves color
    return c
  elseif darkness == 5 then
    -- darkness 5 is not indicated in table, always swaps to black
    return colors.black
  else
    -- use swap table
    return swap_palette[c][darkness]
  end
end

-- a debug function to show all swap palettes
function postprocess.debug_all_swap_palettes()
  postprocess.debug_swap_palette(postprocess.swap_palette_by_darkness, 0)
  postprocess.debug_swap_palette(postprocess.swap_palette_by_darkness_blue_tint, 24)
  postprocess.debug_palette_evolution(postprocess.swap_palette_by_darkness, 0)
  postprocess.debug_palette_evolution(postprocess.swap_palette_by_darkness_blue_tint, 24)
end

local square_size = 4

-- a debug function to show a swap palette
function postprocess.debug_swap_palette(swap_palette, offset_y)
  for c=0,15 do
    for darkness=0,5 do
      local swapped_color = postprocess.get_swapped_color(swap_palette, c, darkness)

      -- draw square representing swapped color
      rectfill(square_size * c,                   offset_y + square_size * darkness,
               square_size * c + square_size - 1, offset_y + square_size * darkness + square_size - 1,
               swapped_color)
    end
  end
end

-- a debug function to show a swap palette
function postprocess.debug_palette_evolution(swap_palette, offset_y)
  local darkness = flr(t() / 0.2) % 6
  for c=0,15 do
    local swapped_color = postprocess.get_swapped_color(swap_palette, c, darkness)

    -- draw square representing swapped color evolving in real time
    rectfill(64 + square_size * c,                   offset_y,
             64 + square_size * c + square_size - 1, offset_y + square_size - 1,
             swapped_color)
  end
end

--#endif

return postprocess
