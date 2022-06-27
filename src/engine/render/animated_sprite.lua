--[[
stateful animated sprite compounded of an animated_sprite_data table and an animation state
it can be used as component of an object rendered with some animation
for objects with a single animation, use a data table containing a single element

usage:

-- data
local character_sprite_data = {
  -- [""] pattern to prevent minification of dynamically accessed keys
  -- if you create your animated_sprite_data using its init(),
  --  by directly accessing sprite_data as table members e.g. character_sprite_data.idle1,
  --  you don't need to do this
  ["idle1"] = sprite_data(sprite_id_location(0, 1), nil, vector(4, 8), colors.peach),
  ["idle2"] = sprite_data(sprite_id_location(1, 1), nil, vector(4, 8), colors.peach),
  ["idle3"] = sprite_data(sprite_id_location(2, 1), nil, vector(4, 8), colors.peach)
}

character_anim_sprite_data = {
  -- same remark as above, but necessary for the animated_sprite API
  --  as it plays animations by name (they won't be minified, so use short names)
  ["idle"] = animated_sprite_data.create(character_sprite_data,
    {"idle1", "idle2", "idle3"},
    15, anim_loop_modes.loop)
}


-- if you care about character count a lot and minify your code though,
--  we recommend not defining #key_access symbol so animated_sprite_data.create is stripped,
--  and directly construct your animation with sprite references, not using protected keys:

-- data
local data = {
  idle1 = sprite_data(sprite_id_location(0, 1), nil, vector(4, 8), colors.peach),
  idle2 = sprite_data(sprite_id_location(1, 1), nil, vector(4, 8), colors.peach),
  idle3 = sprite_data(sprite_id_location(2, 1), nil, vector(4, 8), colors.peach)
}

character_anim_sprite_data = {
  -- animation keys still need to be protected to be used with play()
  ["idle"] = animated_sprite_data({data.idle1, data.idle2, data.idle3},
    15, anim_loop_modes.loop)
}


-- init
character_anim_sprite = animated_sprite(character_anim_sprite_data)
character_anim_sprite:play('idle')

-- update
character_anim_sprite:update()

-- render
character_anim_sprite:render(character.position, flip_x, flip_y, scale)

--]]
local animated_sprite = new_class()

-- parameters
-- data_table        {string: animated_sprite_data}  table of animated sprite data, indexed by animation key (unique name)

-- state
-- playing           bool                            is the animation playing? false if the animation has reached the end and stopped
-- play_speed_frame  float > 0                       playback speed multiplier (in frames per update). it's a float so fractions of frames may be advanced every frame
-- current_anim_key  string|nil                      key in data_table of animation currently played / paused, or nil if no animation is set at all
-- current_step      int                             index of the current sprite shown in the animation sequence, starting at 1 (meaningless if current_anim_key is nil)
-- local_frame       float                           current frame inside the current step, starting at 0 (meaningless if current_anim_key is nil)
--                                                   since play_speed_frame is a float, local_frame is also a float to allow fractional advance
function animated_sprite:init(data_table)
  self.data_table = data_table
  self.playing = false
  self.play_speed_frame = 0
  -- self.current_anim_key = nil  -- commented out to spare characters
  self.current_step = 1
  self.local_frame = 0
end

--#if tostring
function animated_sprite:_tostring()
  local anim_keys = {}
  for anim_key, _ in orderedPairs(self.data_table) do
    add(anim_keys, anim_key.." = ...")
  end
  return "animated_sprite("..joinstr(", ", "{"..joinstr_table(", ", anim_keys).."}", self.playing, self.play_speed_frame, self.current_anim_key, self.current_step, self.local_frame)..")"
end
--#endif

-- play animation with given key: string at playback speed: float (default: 1.)
-- if this animation is not already set, play it from start
-- if this animation is already set, check `from_start`:
-- - if true, force playing it from start
-- - if false, do nothing (if playing, it means continuing to play; if not playing (e.g. stopped at the end), do not replay from start)
--   note that even if the animation is paused, it won't be resumed in this case (because we don't have a flag has_ended to distinguish pause and end)
-- by default, from_start is false, so we continue an animation already playing
function animated_sprite:play(anim_key, from_start, speed)
  assert(self.data_table[anim_key] ~= nil, "animated_sprite:play: self.data_table['"..anim_key.."'] doesn't exist")

  -- default to false, but since nil behaves like false, to spare characters we skip this
  -- from_start = from_start or false

  speed = speed or 1

  -- always update speed. this is useful to change anim speed while continue playing the same animation
  self.play_speed_frame = speed

  if self.current_anim_key ~= anim_key or from_start then
    self.playing = true               -- this will do nothing if forcing replay from start during play
    self.current_anim_key = anim_key  -- this will do nothing if this animation is already set
    self.current_step = 1
    self.local_frame = 0
  end
end

-- stop playing the animation and hide the sprite
-- (consider adding pause which would be more useful)
function animated_sprite:stop()
  self.playing = false
  self.current_anim_key = nil
  self.current_step = 1
  self.local_frame = 0
end

-- update the sprite animation
-- this must be called once per update at 60 fps, before the render phase
-- fractional playback speed is supported, but not negative playback
function animated_sprite:update()
  if self.playing then
    local anim_spr_data = self.data_table[self.current_anim_key]
    -- advance by playback speed
    self.local_frame = self.local_frame + self.play_speed_frame
    -- check if we have reached the end of this step
    -- in case the playback speed is so high we will skip frames,
    --   continue checking until time remainder is less than a step duration
    while self.local_frame >= anim_spr_data.step_frames do
      -- end of step reached, check if there is another sprite afterward
      if self.current_step < #anim_spr_data.sprites then
        -- show next sprite and reset local frame counter
        self.current_step = self.current_step + 1
        self.local_frame = self.local_frame - anim_spr_data.step_frames
      else
        -- end of last step reached, should we loop?
        if anim_spr_data.loop_mode == anim_loop_modes.freeze_first then
          -- stop playing, set frame to 1
          self.playing = false
          self.current_step = 1
          self.local_frame = 0
        elseif anim_spr_data.loop_mode == anim_loop_modes.freeze_last then
          -- stop playing, set frame to last (in practice, current step is already
          --  last unless the playback speed is so high we missed the end)
          self.playing = false
          self.current_step = #anim_spr_data.sprites
          self.local_frame = 0
        elseif anim_spr_data.loop_mode == anim_loop_modes.clear then
          -- stop playing and clear sprite completely
          self:stop()
        else  -- anim_spr_data.loop_mode == anim_loop_modes.loop
          -- continue playing from start
          self.current_step = 1
          self.local_frame = self.local_frame - anim_spr_data.step_frames
        end
      end
    end
  end
end

-- render the current sprite data with passed arguments
-- an animation must be played to properly show a sprite (even an animation with a single
--  step for a static sprite), but if no animation has been played/paused/stopped at all,
--  we still try show the first sprite of the 'idle' animation for debugging at least
-- position  vector
-- flip_x    bool
-- flip_y    bool
-- scale     float
function animated_sprite:render(position, flip_x, flip_y, angle, scale)
  if self.current_anim_key then
    -- an animation is set, render even if not playing since we want to show a still frame
    --   at the end of a non-looped anim (freeze_first and freeze_last modes only)
    -- todo: for one-time fx, we actually want to stop rendering the fx after playing
    --   so add a param in animated_sprite_data to effectively stop rendering once anim is over
    local anim_spr_data = self.data_table[self.current_anim_key]
    local current_sprite_data = anim_spr_data.sprites[self.current_step]
    assert(current_sprite_data, "no sprite data found at anim_spr_data.sprites["..self.current_step.."]")
    current_sprite_data:render(position, flip_x, flip_y, angle, scale)
  end
end

return animated_sprite
