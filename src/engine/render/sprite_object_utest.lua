require("engine/test/bustedhelper")
local sprite_object = require("engine/render/sprite_object")

local sprite_data = require("engine/render/sprite_data")

describe('sprite', function ()

  describe('init', function ()

    it('should init a sprite with a sprite_data, visible, default position: (0, 0), default scale: 1', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      local spr_object = sprite_object(spr_data)
      assert.are_same({spr_data, true, vector(0, 0), 1}, {spr_object.sprite_data, spr_object.visible, spr_object.position, spr_object.scale})
    end)

    it('should init a sprite with a sprite_data, visible, position: (2, 3) (copy), scale: 2', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      local position = vector(2, 3)
      local spr_object = sprite_object(spr_data, position, 2)
      assert.are_same({spr_data, true, vector(2, 3), 2}, {spr_object.sprite_data, spr_object.visible, spr_object.position, spr_object.scale})
      assert.is_false(rawequal(position, spr_object.position))
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(sprite_data, "render")
    end)

    teardown(function ()
      sprite_data.render:revert()
    end)

    after_each(function ()
      sprite_data.render:clear()
    end)

    it('should delegate drawing to sprite_data.render', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(11, 10), colors.yellow)
      local spr_object = sprite_object(spr_data, vector(2, 3))
      spr_object.scale = 2

      spr_object:draw()

      assert.spy(sprite_data.render).was_called(1)
      assert.spy(sprite_data.render).was_called_with(match.ref(spr_data), vector(2, 3), false, false, 0, 2)
    end)

    it('(not visible) should not draw at all', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(11, 10), colors.yellow)
      local spr_object = sprite_object(spr_data, vector(2, 3))
      spr_object.visible = false

      spr_object:draw()

      assert.spy(sprite_data.render).was_not_called()
    end)

  end)

end)
