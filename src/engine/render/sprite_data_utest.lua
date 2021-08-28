require("engine/test/bustedhelper")
local sprite_data = require("engine/render/sprite_data")

describe('sprite', function ()

  describe('init', function ()
    it('should init a sprite with an id_loc', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      assert.are_same(sprite_id_location(1, 3), spr_data.id_loc)
    end)
    it('should init a sprite with the passed span', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(4, 5))
      assert.are_same(tile_vector(4, 5), spr_data.span)
    end)
    it('should init a sprite with a span of (1, 1) by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3))
      assert.are_same(tile_vector(1, 1), spr_data.span)
    end)
    it('should init a sprite with the passed pivot', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil, vector(2, 4))
      assert.are_same(vector(2, 4), spr_data.pivot)
    end)
    it('should init a sprite with a pivot of (0, 0) by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil)
      assert.are_same(vector.zero(), spr_data.pivot)
    end)
    it('should init a sprite with the passed transparent colors', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil, nil, {colors.pink, colors.red})
      assert.are_equal(color_to_bitmask(colors.pink) | color_to_bitmask(colors.red), spr_data.transparent_color_bitmask)
    end)
    it('should init a sprite with the passed transparent color', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), nil, nil, colors.pink)
      assert.are_equal(color_to_bitmask(colors.pink), spr_data.transparent_color_bitmask)
    end)
    it('should init a sprite with a transparent color of black by default', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(4, 5), vector(2, 4), nil)
      assert.are_equal(color_to_bitmask(colors.black), spr_data.transparent_color_bitmask)
    end)
  end)

  describe('_tostring', function ()

    it('sprite_data((1, 3) ...) => "sprite_data(sprite_id_location(1, 3) ...)"', function ()
      local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4), colors.red)
      assert.are_equal("sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(2, 4), 0x0080.0000)", spr_data:_tostring())
    end)

  end)

  describe('render', function ()

    local spr_data = sprite_data(sprite_id_location(1, 3), tile_vector(2, 3), vector(11, 10), colors.yellow)
    local spr_data2 = sprite_data(sprite_id_location(1, 3), tile_vector(2, 1), vector(8, 4))

    setup(function ()
      stub(_G, "spr_r90")
      stub(_G, "sspr")
      stub(_G, "palt")
    end)

    teardown(function ()
      spr_r90:revert()
      sspr:revert()
      palt:revert()
    end)

    after_each(function ()
      spr_r90:clear()
      sspr:clear()
      palt:clear()
    end)

    it('(no scale) should delegate rendering to spr_r90', function ()
      spr_data:render(vector(41, 80), true, false, 0.5)

      assert.spy(spr_r90).was_called(1)
      assert.spy(spr_r90).was_called_with(1, 3, 41, 80, 2, 3, true, false, 11, 10, 0.5, spr_data.transparent_color_bitmask)
    end)

    it('(scale == 1) should delegate rendering to spr_r90', function ()
      spr_data:render(vector(41, 80), true, false, 0.5, 1)

      assert.spy(spr_r90).was_called(1)
      assert.spy(spr_r90).was_called_with(1, 3, 41, 80, 2, 3, true, false, 11, 10, 0.5, spr_data.transparent_color_bitmask)
    end)

    it('(scale ~= 1) should delegate rendering to sspr with palt', function ()
      spr_data:render(vector(41, 80), true, false, 0, 2)

      assert.spy(sspr).was_called(1)
      assert.spy(sspr).was_called_with(8 * 1, 8 * 3, 8 * 2, 8 * 3, 41 - 2 * 11, 80 - 2 * 10, 2 * 8 * 2, 2 * 8 * 3, true, false)

      assert.spy(palt).was_called(2)
      assert.spy(palt).was_called_with()  -- before sspr, but cannot verify
      assert.spy(palt).was_called_with(spr_data.transparent_color_bitmask)  -- after sspr, but cannot verify
    end)

    it('(angle ~= 0 [1] and scale ~= 1) should assert', function ()
      assert.has_error(function ()
        spr_data:render(vector(41, 80), true, false, 0.5, 2)
      end)
    end)

  end)

end)
