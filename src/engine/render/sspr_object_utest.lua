require("engine/test/bustedhelper")
local sspr_object = require("engine/render/sspr_object")

local sprite_data = require("engine/render/sprite_data")

describe('sprite', function ()

  describe('init', function ()

    it('should init a sprite with sspr coordinates, visible, position, transparent color mask', function ()
      local sspr_object = sspr_object(0, 1, 2, 3, colors.dark_purple, vector(4, 5))
      assert.are_same({0, 1, 2, 3, true, vector(4, 5)}, {sspr_object.sx, sspr_object.sy, sspr_object.sw, sspr_object.sh, sspr_object.visible, sspr_object.position})
      assert.are_equal(generic_transparent_color_arg_to_mask(colors.dark_purple), sspr_object.transparent_color_bitmask)
    end)

    it('should init a sprite with sspr position default to (0, 0)', function ()
      local sspr_object = sspr_object(0, 1, 2, 3, colors.dark_purple)
      assert.are_same(vector(0, 0), sspr_object.position)
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(_G, "sspr")
    end)

    teardown(function ()
      sspr:revert()
    end)

    after_each(function ()
      sspr:clear()
    end)

    it('should delegate drawing to sspr', function ()
      local sspr_object = sspr_object(0, 1, 2, 3, colors.dark_purple, vector(4, 5))
      sspr_object.scale = 2

      sspr_object:draw()

      assert.spy(sspr).was_called(1)
      assert.spy(sspr).was_called_with(0, 1, 2, 3, 4, 5)
    end)

    it('(not visible) should not draw at all', function ()
      local sspr_object = sspr_object(0, 1, 2, 3, colors.dark_purple, vector(4, 5))
      sspr_object.visible = false

      sspr_object:draw()

      assert.spy(sspr).was_not_called()
    end)

  end)

end)
