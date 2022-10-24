require("engine/test/bustedhelper")
local animated_sprite_object = require("engine/render/animated_sprite_object")

local animated_sprite = require("engine/render/animated_sprite")
local sprite_data = require("engine/render/sprite_data")

describe('animated_sprite_object', function ()

  describe('init', function ()

    it('should init a sprite with animated sprite data, visible, default position: (0, 0), no flip, default scale: 1', function ()
      local dummy_animated_spr_data = {}
      local spr_object = animated_sprite_object(dummy_animated_spr_data)
      -- normally we should spy on base constructor, but to simplify just check that data table was set
      assert.are_equal(dummy_animated_spr_data, spr_object.data_table)
      assert.are_same({true, vector(0, 0), nil, nil, 1}, {spr_object.visible, spr_object.position, spr_object.flip_x, spr_object.flip_y, spr_object.scale})
    end)

    it('should init a sprite with animated sprite data, visible, position: (2, 3) (copy), flip, scale: 2', function ()
      local dummy_animated_spr_data = {}
      local position = vector(2, 3)
      local spr_object = animated_sprite_object(dummy_animated_spr_data, position, true, false, 2)
      -- normally we should spy on base constructor, but to simplify just check that data table was set
      assert.are_equal(dummy_animated_spr_data, spr_object.data_table)
      assert.are_same({true, vector(2, 3), true, false, 2}, {spr_object.visible, spr_object.position, spr_object.flip_x, spr_object.flip_y, spr_object.scale})
      assert.is_false(rawequal(position, spr_object.position))
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(animated_sprite, "render")
    end)

    teardown(function ()
      animated_sprite.render:revert()
    end)

    after_each(function ()
      animated_sprite.render:clear()
    end)

    it('should delegate drawing to base animated_sprite.render', function ()
      local dummy_animated_spr_data = {}
      local spr_object = animated_sprite_object({dummy_animated_spr_data}, vector(2, 3), true, false, 2)

      spr_object:draw()

      assert.spy(animated_sprite.render).was_called(1)
      assert.spy(animated_sprite.render).was_called_with(match.ref(spr_object), vector(2, 3), true, false, 0, 2)
    end)

    it('(not visible) should not draw at all', function ()
      local dummy_animated_spr_data = {}
      local spr_object = animated_sprite_object(dummy_animated_spr_data, vector(2, 3))
      spr_object.visible = false

      spr_object:draw()

      assert.spy(animated_sprite.render).was_not_called()
    end)

  end)

end)
