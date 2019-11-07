-- struct containing data on animated sprite: sprite references and timing
local animated_sprite_data = new_struct()

-- mode describing animated sprite behavior when animation is over
anim_loop_modes = enum {
  'freeze_first',  -- go back to 1st frame and stop playing
  'freeze_last',   -- keep last frame and stop playing
  'clear',         -- stop showing sprite completely
  'loop',          -- go back to 1st frame and continue playing
}

-- sprites      {sprite_data}    sequence of sprites to play in order
-- step_frames  int              how long a single sprite (step) is displayed, in frames
-- loop_mode    anim_loop_modes  what should anim do at the end of a cycle?
function animated_sprite_data:_init(sprites, step_frames, loop_mode)
  assert(#sprites > 0)
  assert(step_frames > 0)

  self.sprites = sprites
  self.step_frames = step_frames
  self.loop_mode = loop_mode
end

-- factory function to create animated sprite data from a table
--   of sprite data, and a sequence of keys
function animated_sprite_data.create(sprite_data_table, sprite_keys, step_frames, loop_mode)
  local sprites = {}
  for sprite_key in all(sprite_keys) do
    add(sprites, sprite_data_table[sprite_key])
  end
  return animated_sprite_data(sprites, step_frames, loop_mode)
end

--#if log
function animated_sprite_data:_tostring()
  return "animated_sprite_data("..joinstr(", ", "["..#self.sprites.." sprites]", self.step_frames, self.loop_mode)..")"
end
--#endif

return animated_sprite_data
