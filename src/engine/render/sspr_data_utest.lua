require("engine/test/bustedhelper")
local sspr_data = require("engine/render/sspr_data")

describe('sprite', function ()

  describe('init', function ()
    it('should init a sprite with source coordinates and dimensions', function ()
      local spr_data = sspr_data(11, 22, 33, 44)
      assert.are_same({11, 22, 33, 44}, {spr_data.sx, spr_data.sy, spr_data.sw, spr_data.sh})
    end)
    it('should init a sprite with the passed pivot', function ()
      local spr_data = sspr_data(11, 22, 33, 44, vector(2, 4))
      assert.are_same(vector(2, 4), spr_data.pivot)
    end)
    it('should init a sprite with a pivot of (0, 0) by default', function ()
      local spr_data = sspr_data(11, 22, 33, 44, nil)
      assert.are_same(vector.zero(), spr_data.pivot)
    end)

    it('should init a sprite with the passed transparent colors', function ()
      local spr_data = sspr_data(11, 22, 33, 44, nil, {colors.pink, colors.red})
      assert.are_equal(generic_transparent_color_arg_to_mask({colors.pink, colors.red}), spr_data.transparent_color_bitmask)
    end)
    it('should init a sprite with the passed transparent color', function ()
      local spr_data = sspr_data(11, 22, 33, 44, nil, colors.pink)
      assert.are_equal(generic_transparent_color_arg_to_mask(colors.pink), spr_data.transparent_color_bitmask)
    end)
    it('should init a sprite with a transparent color of black by default', function ()
      local spr_data = sspr_data(11, 22, 33, 44, vector(2, 4), nil)
      assert.are_equal(generic_transparent_color_arg_to_mask(colors.black), spr_data.transparent_color_bitmask)
    end)
  end)

  describe('_tostring', function ()

    it('sspr_data((1, 3) ...) => "sspr_data(11, 22, 33, 44, ...)"', function ()
      local spr_data = sspr_data(11, 22, 33, 44, vector(2, 4), colors.red)
      assert.are_equal("sspr_data(11, 22, 33, 44, vector(2, 4), 0x0080.0000)", spr_data:_tostring())
    end)

  end)

  describe('render', function ()

    local spr_data = sspr_data(11, 22, 33, 44, vector(11, 10), colors.yellow)

    setup(function ()
      stub(_G, "sspr")
      stub(_G, "palt")
    end)

    teardown(function ()
      sspr:revert()
      palt:revert()
    end)

    after_each(function ()
      sspr:clear()
      palt:clear()
    end)

    it('should delegate rendering to sspr with palt', function ()
      spr_data:render(vector(41, 80), true, false, 0, 2)

      assert.spy(sspr).was_called(1)
      -- pivot x of 2 is adjusted by flip_x to sw - 11 = 33 - 11 = 22
      assert.spy(sspr).was_called_with(11, 22, 33, 44, 41 - 2 * 22, 80 - 2 * 10, 2 * 33, 2 * 44, true, false)

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
