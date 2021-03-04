-- postprocessing object
-- usage:
-- 1. create a postprocess instance in your gamestate init, store it as member
-- 2. after the end of your gamestate render, call postprocess:apply()
-- 3. change parameters during your animation sequences
local postprocess = new_class()

-- darkness swap palette
-- each color is associated to 6 levels of darkness
-- 0 is not represented, we just don't swap colors
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
  --[[ [colors.blue] = ]]              {colors.indigo,      colors.dark_purple, colors.dark_blue,   colors.dark_blue},
  --[[ [colors.indigo] = ]]            {colors.dark_purple, colors.dark_purple, colors.dark_blue,   colors.dark_blue},
  --[[ [colors.pink] = ]]              {colors.brown,       colors.brown,       colors.dark_purple, colors.dark_purple},
  --[[ [colors.peach] = ]]             {colors.orange,      colors.brown,       colors.dark_gray,   colors.dark_gray}
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
    -- black can't get darker, just check the other 15 colors
    for c = 1, 15 do
      pal(c, postprocess.swap_palette_by_darkness[c][self.darkness], 1)
    end
  else
    -- everything is black at level 5+, so just clear screen
    cls()
  end
end

return postprocess
