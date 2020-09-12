require("engine/test/bustedhelper")
local sprite_data = require("engine/render/sprite_data")
local animated_sprite_data = require("engine/render/animated_sprite_data")

describe('animated_sprite_data', function ()

  local spr_data1 = sprite_data(sprite_id_location(1, 0), tile_vector(1, 2), vector(4, 6))
  local spr_data2 = sprite_data(sprite_id_location(2, 0), tile_vector(1, 2), vector(4, 6))
  local spr_data_table = {step1 = spr_data1, step2 = spr_data2}

  describe('_init', function ()
    it('should init a sprite with all parameters', function ()
      local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 2, anim_loop_modes.freeze_last)
      assert.are_same({{spr_data1, spr_data2}, 2, anim_loop_modes.freeze_last},
        {anim_spr_data.sprites, anim_spr_data.step_frames, anim_spr_data.loop_mode})
    end)
  end)

  describe('create_static', function ()
    it('should create an animated sprite data from a single static sprite', function ()
      local anim_spr_data = animated_sprite_data.create_static(spr_data1)
      assert.are_same({{spr_data1}, 1, anim_loop_modes.freeze_last},
        {anim_spr_data.sprites, anim_spr_data.step_frames, anim_spr_data.loop_mode})
    end)
  end)

  describe('create', function ()
    it('should create an animated sprite data from a sprite data table and sprite keys, with step_frames and looping', function ()
      local anim_spr_data = animated_sprite_data.create(spr_data_table, {"step1", "step2"}, 4, anim_loop_modes.freeze_last)
      assert.are_same({{spr_data1, spr_data2}, 4, anim_loop_modes.freeze_last},
        {anim_spr_data.sprites, anim_spr_data.step_frames, anim_spr_data.loop_mode})
    end)
  end)

  describe('_tostring', function ()

    it('should return a string describing the number of sprites, step duration in frames and whether it loops', function ()
      local anim_spr_data = animated_sprite_data({spr_data1, spr_data2}, 2, anim_loop_modes.freeze_last)
      assert.are_equal("animated_sprite_data([2 sprites], 2, 2)", anim_spr_data:_tostring())
    end)

  end)

end)
