-- exceptionally a global require
-- make sure to require it in your common_game.lua too if using minify lv3
-- for early definition (if using unify, redundant require will be removed)
require("engine/render/animated_sprite_data_enums")

-- struct containing data on animated sprite: sprite references and timing
local animated_sprite_data = new_struct()

-- sprites      {sprite_data}    sequence of sprites to play in order
-- step_frames  int              how long a single sprite (step) is displayed, in frames
-- loop_mode    anim_loop_modes  what should anim do at the end of a cycle?
function animated_sprite_data:init(sprites, step_frames, loop_mode)
  assert(#sprites > 0)
  assert(step_frames > 0)

  self.sprites = sprites
  self.step_frames = step_frames
  self.loop_mode = loop_mode
end

-- factory function to create animated sprite data with single frame
function animated_sprite_data.create_static(static_sprite_data)
  return animated_sprite_data({static_sprite_data}, 1, anim_loop_modes.freeze_last)
end

--#if key_access
-- factory function to create animated sprite data from a table
--   of sprite data, and a sequence of keys
-- this requires keys not to be minified which may make data code a little bigger,
--  so only define this if developer wants to use string key access
function animated_sprite_data.create(sprite_data_table, sprite_keys, step_frames, loop_mode)
  local sprites = {}
  for sprite_key in all(sprite_keys) do
    assert(sprite_data_table[sprite_key], "sprite_data_table has no entry for key: "..tostr(sprite_key))
    add(sprites, sprite_data_table[sprite_key])
  end
  return animated_sprite_data(sprites, step_frames, loop_mode)
end
--#endif

--#if tostring
function animated_sprite_data:_tostring()
  return "animated_sprite_data("..joinstr(", ", "["..#self.sprites.." sprites]", self.step_frames, self.loop_mode)..")"
end
--#endif

return animated_sprite_data
