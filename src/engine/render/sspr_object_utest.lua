require("engine/test/bustedhelper")
local sspr_object = require("engine/render/sspr_object")

local sspr_data = require("engine/render/sspr_data")

describe('sspr_object', function ()

  describe('init', function ()

    it('should init a sprite with a sspr_data, visible, default position: (0, 0), default scale: 1', function ()
      local sspr_data = sspr_data(0, 1, 2, 3)
      local sspr_object = sspr_object(sspr_data)
      assert.are_same({sspr_data, true, vector(0, 0), 1}, {sspr_object.sspr_data, sspr_object.visible, sspr_object.position, sspr_object.scale})
    end)

    it('should init a sprite with a sspr_data, visible, position: (2, 3) (copy), scale: 2', function ()
      local sspr_data = sspr_data(0, 1, 2, 3)
      local position = vector(2, 3)
      local sspr_object = sspr_object(sspr_data, position, 2)
      assert.are_same({sspr_data, true, vector(2, 3), 2}, {sspr_object.sspr_data, sspr_object.visible, sspr_object.position, sspr_object.scale})
      assert.is_false(rawequal(position, sspr_object.position))
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(sspr_data, "render")
    end)

    teardown(function ()
      sspr_data.render:revert()
    end)

    after_each(function ()
      sspr_data.render:clear()
    end)

    it('should delegate drawing to sspr_data.render', function ()
      local sspr_data = sspr_data(0, 1, 2, 3, vector(11, 10), colors.yellow)
      local sspr_object = sspr_object(sspr_data, vector(2, 3))
      sspr_object.scale = 2

      sspr_object:draw()

      assert.spy(sspr_data.render).was_called(1)
      assert.spy(sspr_data.render).was_called_with(match.ref(sspr_data), vector(2, 3), false, false, 0, 2)
    end)

    it('(not visible) should not draw at all', function ()
      local sspr_data = sspr_data(0, 1, 2, 3, vector(11, 10), colors.yellow)
      local sspr_object = sspr_object(sspr_data, vector(2, 3))
      sspr_object.visible = false

      sspr_object:draw()

      assert.spy(sspr_data.render).was_not_called()
    end)

  end)

end)
