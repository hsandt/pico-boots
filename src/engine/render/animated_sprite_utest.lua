require("engine/test/bustedhelper")
local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")
local animated_sprite = require("engine/render/animated_sprite")

describe('animated_sprite', function ()

  local spr_data1 = sprite_data(sprite_id_location(1, 0), tile_vector(1, 2), vector(4, 6))
  local spr_data2 = sprite_data(sprite_id_location(2, 0), tile_vector(1, 2), vector(4, 6))
  local spr_data3 = sprite_data(sprite_id_location(3, 0), tile_vector(1, 2), vector(4, 6))
  local anim_spr_data_freeze_first = animated_sprite_data({spr_data1, spr_data2, spr_data3}, 10, anim_loop_modes.freeze_first)
  local anim_spr_data_freeze_last = animated_sprite_data({spr_data1, spr_data2, spr_data3}, 10, anim_loop_modes.freeze_last)
  local anim_spr_data_clear = animated_sprite_data({spr_data1, spr_data2, spr_data3}, 10, anim_loop_modes.clear)
  local anim_spr_data_loop = animated_sprite_data({spr_data1, spr_data2, spr_data3}, 10, anim_loop_modes.loop)
  local anim_spr_data_table = {
    freeze_first = anim_spr_data_freeze_first,
    freeze_last = anim_spr_data_freeze_last,
    clear = anim_spr_data_clear,
    loop = anim_spr_data_loop
  }
  local anim_spr_data_table_with_idle = {
    idle = anim_spr_data_freeze_last
  }

  describe('init', function ()
    it('should init an animated sprite with data, automatically playing from step 1, frame 0', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      assert.are_same({anim_spr_data_table, false, 0., nil, 1, 0},
        {anim_spr.data_table, anim_spr.playing, anim_spr.play_speed_frame, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)
  end)

  describe('_tostring', function ()

    it('should return a string describing data, current step and local frame', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1.5
      anim_spr.current_anim_key = "idle"
      anim_spr.current_step = 2
      anim_spr.local_frame = 5
      assert.are_equal("animated_sprite({clear = ..., freeze_first = ..., freeze_last = ..., loop = ...}, true, 1.5, idle, 2, 5)", anim_spr:_tostring())
    end)

  end)

  describe('play', function ()

    it('should assert if the anim_key is not found', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)

      assert.has_error(function() anim_spr:play("unknown") end,
        "animated_sprite:play: self.data_table['unknown'] doesn't exist")
    end)

    it('should start playing a new anim from the first step, first frame', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)

      anim_spr:play("freeze_first")

      assert.are_same({true, "freeze_first", 1, 0},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should start playing the current anim from the first step, first frame if passing the current anim and from_start is true', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 2
      anim_spr.local_frame = 5

      anim_spr:play("freeze_first", true)

      assert.are_same({true, "freeze_first", 1, 0},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should continue playing the current anim if passing the current anim and from_start is false', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 2
      anim_spr.local_frame = 5

      anim_spr:play("freeze_first", false)

      assert.are_same({true, "freeze_first", 2, 5},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should not resume the current anim if paused, passing the current anim and from_start is false', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = false
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 2
      anim_spr.local_frame = 5

      anim_spr:play("freeze_first", false)

      assert.are_same({false, "freeze_first", 2, 5},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('set play speed to 1 by default', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = false
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 0
      anim_spr.local_frame = 0

      anim_spr:play("freeze_first", false)

      assert.are_equal(1, anim_spr.play_speed_frame)
    end)

    it('set play speed to any custom speed', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = false
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 0
      anim_spr.local_frame = 0

      anim_spr:play("freeze_first", true, 2.3)

      assert.are_equal(2.3, anim_spr.play_speed_frame)
    end)

  end)

  describe('stop', function ()

    it('should reset state', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 2
      anim_spr.local_frame = 5

      anim_spr:stop()

      assert.are_same({false, nil, 1, 0},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

  end)

  describe('update', function ()

    it('should do nothing when not playing', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = false
      anim_spr.play_speed_frame = 1
      anim_spr.current_step = 9
      anim_spr.local_frame = 99

      anim_spr:update()

      assert.are_same({false, 9, 99},
        {anim_spr.playing, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should increment the local frame if under the animation step_frames at playback speed 1', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 1
      anim_spr.local_frame = 8  -- data.step_frames is 10, so frames play from 0 to 9

      anim_spr:update()

      assert.are_same({1, 9},
        {anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should increase the local frame with playback speed if under the animation step_frames', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1.5
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 1
      anim_spr.local_frame = 8.2  -- data.step_frames is 10, so frames play from 0 to 9

      anim_spr:update()

      assert.are_same({1, 9.7},
        {anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should reset local frame and enter next step when step_frames is reached at playback speed 1', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 1
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({2, 0},
        {anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should decrease the local frame by step_frames and enter next step when step_frames is reached when playback speed is not 1', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 2
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 1
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({2, 1},
        {anim_spr.current_step, anim_spr.local_frame})
    end)

    it('should decrease the local frame by 2*step_frames and advance by 2 steps when playback speed is enough to cover 2 step_frames (with initial fraction offset)', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 14.5
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 1
      anim_spr.local_frame = 8
      -- data.step_frames = 10, and we will reach 8 + 14.5 = 22.5, so 2 steps ahead and 2.5 remaining
      -- this is testing the internal while loop supporting high playback speeds with remainders in chain

      anim_spr:update()

      assert.are_same({3, 2.5},
        {anim_spr.current_step, anim_spr.local_frame})
    end)

    it('(looping) should continue playing from the start when end of animation has been reached', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1
      anim_spr.current_anim_key = "loop"
      anim_spr.current_step = 3
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({true, "loop", 1, 0},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('(looping) should continue playing from the start when end of animation has been reached, with any remaining frame fraction', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 2.5
      anim_spr.current_anim_key = "loop"
      anim_spr.current_step = 3
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({true, "loop", 1, 1.5},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('(looping) should continue playing from the start when end of animation has been reached with a high playback speed skipping 1 frame', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 17
      anim_spr.current_anim_key = "loop"
      anim_spr.current_step = 2
      anim_spr.local_frame = 5
      -- data.step_frames = 10, and we will reach 5 + 17 = 22, so 2 steps ahead and 2 remaining, but there are only 3 steps
      -- so we go back to 1
      -- this is testing the internal while loop supporting high playback speeds with remainders in chain

      anim_spr:update()

      assert.are_same({true, "loop", 1, 2},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('(freeze first) should stop playing when end of animation has been reached, reverting to 1st frame (reset local_frame to 0)', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 3
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({false, "freeze_first", 1, 0},  -- 10 doesn't exist, but ok for stopped anim
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('(freeze last) should stop playing when end of animation has been reached, keeping local frame equal to step frames (reset local_frame to 0)', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1
      anim_spr.current_anim_key = "freeze_last"
      anim_spr.current_step = 3
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      assert.are_same({false, "freeze_last", 3, 0},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

    it('(clear) should stop playing when end of animation has been reached, clearing sprite completely (reset local_frame to 0)', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.playing = true
      anim_spr.play_speed_frame = 1
      anim_spr.current_anim_key = "clear"
      anim_spr.current_step = 3
      anim_spr.local_frame = 9  -- data.step_frames - 1

      anim_spr:update()

      -- we don't stub stop() so we can check the resulting state directly
      assert.are_same({false, nil, 1, 0},
        {anim_spr.playing, anim_spr.current_anim_key, anim_spr.current_step, anim_spr.local_frame})
    end)

  end)

  describe('render', function ()

    setup(function ()
      stub(sprite_data, "render")
      stub(_G, "warn")
    end)

    teardown(function ()
      sprite_data.render:revert()
      warn:revert()
    end)

    after_each(function ()
      sprite_data.render:clear()
      warn:clear()
    end)

    it('(when not playing) should do nothing', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)

      anim_spr:render(vector(41, 80), false, true, 0.25)

      assert.spy(sprite_data.render).was_not_called()
    end)

    it('(when playing) should render the sprite for current animation and step, with passed arguments', function ()
      local anim_spr = animated_sprite(anim_spr_data_table)
      anim_spr.current_anim_key = "freeze_first"
      anim_spr.current_step = 2  -- matches spr_data2
      anim_spr.local_frame = 5

      anim_spr:render(vector(41, 80), false, true, 0.25)

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(spr_data2), vector(41, 80), false, true, 0.25)
    end)

  end)

end)
