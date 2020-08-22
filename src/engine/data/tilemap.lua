local tilemap = new_struct()

-- content    {{int}}     2-dimensional sequence of tile ids, by row, then column
function tilemap:_init(content)
  self.content = content
end

--#if busted
-- this custom equality is defined for utests only
-- in general it's risky to do that because semantics change,
--  but fortunately we know that the game will never have to compare
--  tilemaps in reality!
-- it's also a hotfix for luassert that unfortunately still considers
--  struct __eq in assert.are_same, and default __eq is are_same_shallow
--  which is not good enough to compare sub-tables;
--  it was simplified to spare tokens, but tilemap itself is #itest-only
--  and this __eq is #busted only so it's not a problem
function tilemap.__eq(lhs, rhs)
  return are_same(lhs.content, rhs.content)
end
--#endif

-- load the content into the current map
function tilemap:load(content)
  tilemap.clear_map()
  for i = 1, #self.content do
    local row = self.content[i]
    for j = 1, #row do
      mset(j - 1, i - 1, row[j])
    end
  end
end

-- clear map, using appropriate interface (pico8 or busted pico8api)
function tilemap.clear_map()
--#if busted
  pico8:clear_map()
--#endif

--[[#pico8
  -- clear map data
  memset(0x2000, 0, 0x1000)
--#pico8]]
end

return tilemap
