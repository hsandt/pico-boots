-- stateful animated sprite compounded of an animated_sprite_data table and an animation state
-- it can be used as component of an object rendered with some animation
-- for objects with a single animation, use a data table containing a single element
animated_sprite = new_class()

-- parameters
-- data_table        {string: animated_sprite_data}  table of animated sprite data, indexed by animation key (unique name)

-- state
-- playing           bool                            is the animation playing? false if the animation has reached the end and stopped
-- play_speed_frame  float > 0                       playback speed multiplier (in frames per update). it's a float so fractions of frames may be advanced every frame
-- current_anim_key  string|nil                      key in data_table of animation currently played / paused, or nil if no animation is set at all
-- current_step      int|nil                         index of the current sprite shown in the animation sequence, starting at 1, or nil if no animation is set at all
-- local_frame       float|nil                       current frame inside the current step, starting at 0, or nil if no animation is set at all
--                                                   since play_speed_frame is a float, local_frame is also a float to allow fractional advance
function animated_sprite:_init(data_table)
  self.data_table = data_table
  self.playing = false
  self.play_speed_frame = 0.
  self.current_anim_key = nil
  self.current_step = nil
  self.local_frame = nil
end

--#if log
function animated_sprite:_tostring()
  return "animated_sprite("..joinstr(", ", nice_dump(self.data_table, true), self.playing, self.play_speed_frame, self.current_anim_key, self.current_step, self.local_frame)..")"
end
--#endif

-- play animation with given key: string at playback speed: float (default: 1.)
-- if this animation is not already set, play it from start
-- if this animation is already set, check `from_start`:
-- - if true, force playing it from start
-- - if false, do nothing (if playing, it means continuing to play; if not playing (e.g. stopped at the end), do not replay from start)
--   note that even if the animation is paused, it won't be resumed in this case (because we don't have a flag has_ended to distinguish pause and end)
-- by default, continue animation already playing
function animated_sprite:play(anim_key, from_start, speed)
  assert(self.data_table[anim_key] ~= nil, "animated_sprite:play: self.data_table['"..anim_key.."'] doesn't exist")

  if from_start == nil then
    from_start = false
  end

  speed = speed or 1.

  -- always update speed. this is useful to change anim speed while continue playing the same animation
  self.play_speed_frame = speed

  if self.current_anim_key ~= anim_key or from_start then
    self.playing = true               -- this will do nothing if forcing replay from start during play
    self.current_anim_key = anim_key  -- this will do nothing if this animation is already set
    self.current_step = 1
    self.local_frame = 0
  end
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
        if anim_spr_data.looping then
          -- continue playing from start
          self.current_step = 1
          self.local_frame = self.local_frame - anim_spr_data.step_frames
        else
          -- stop playing
          self.playing = false
          break
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
function animated_sprite:render(position, flip_x, flip_y)
  if self.current_anim_key then
    -- an animation is set, render even if not playing since we want to show the last frame
    --   of a non-looped anim as a still frame
    local anim_spr_data = self.data_table[self.current_anim_key]
    local current_sprite_data = anim_spr_data.sprites[self.current_step]
    current_sprite_data:render(position, flip_x, flip_y)
  else
    -- no animation is playing; this is not normal behavior, but we try to show the first
    -- 'idle' sprite to debug more easily
    warn("animated_sprite:render: no animation played, trying to render 'idle' first sprite")
    local anim_spr_data = self.data_table['idle']
    if anim_spr_data then
      local current_sprite_data = anim_spr_data.sprites[1]
      current_sprite_data:render(position, flip_x, flip_y)
    else
      warn("animated_sprite:render: 'idle' animation not found, cannot render sprite at all")
    end
  end
end

return animated_sprite
