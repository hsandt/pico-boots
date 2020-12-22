-- postprocessing object
-- usage:
-- 1. create a postprocess instance in your gamestate init, store it as member
-- 2. after the end of your gamestate render, call postprocess:apply()
-- 3. change parameters during your animation sequences
local postprocess = new_class()

-- darkness swap palette
-- each color is associated to 2 levels of darkness (darker, very dark)
-- we skip black which doesn't get darker, so we can start at index 1 and we don't need
--  explicit keys at all
postprocess.swap_palette_by_darkness = {
  -- [colors.black] = {colors.black, colors.black},
  --[[ [colors.dark_blue] = ]] {colors.black, colors.black},
  --[[ [colors.dark_purple] = ]] {colors.black, colors.black},
  --[[ [colors.dark_green] = ]] {colors.black, colors.black},
  --[[ [colors.brown] = ]] {colors.black, colors.black},
  --[[ [colors.dark_gray] = ]] {colors.black, colors.black},
  --[[ [colors.light_gray] = ]] {colors.dark_gray, colors.black},
  --[[ [colors.white] = ]] {colors.light_gray, colors.dark_gray},
  --[[ [colors.red] = ]] {colors.dark_purple, colors.black},
  --[[ [colors.orange] = ]] {colors.brown, colors.black},
  --[[ [colors.yellow] = ]] {colors.orange, colors.brown},
  --[[ [colors.green] = ]] {colors.dark_green, colors.black},
  --[[ [colors.blue] = ]] {colors.dark_blue, colors.black},
  --[[ [colors.indigo] = ]] {colors.dark_gray, colors.black},
  --[[ [colors.pink] = ]] {colors.dark_purple, colors.black},
  --[[ [colors.peach] = ]] {colors.orange, colors.brown}
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
  elseif self.darkness < 3 then
    -- black can't get darker, just check the other 15 colors
    for c = 1, 15 do
      pal(c, postprocess.swap_palette_by_darkness[c][self.darkness], 1)
    end
  else
    -- everything is black at level 3, so just clear screen
    cls()
  end
end

return postprocess
