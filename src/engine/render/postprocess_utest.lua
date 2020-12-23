require("engine/test/bustedhelper")
local postprocess = require("engine/render/postprocess")

describe('postprocess', function ()

  describe('init', function ()

    it('should init a postprocess with default parameters', function ()
      local pp = postprocess()
      assert.are_equal(0, pp.darkness)
    end)

  end)

  describe('apply', function ()

    setup(function ()
      stub(_G, "pal")
      stub(_G, "cls")
    end)

    teardown(function ()
      pal:revert()
      cls:revert()
    end)

    after_each(function ()
      pal:clear()
      cls:clear()
    end)

    it('(darkness 0) should reset palette', function ()
      local pp = postprocess()
      pp.darkness = 0

      pp:apply()

      assert.spy(pal).was_called(1)
      assert.spy(pal).was_called_with()
    end)

    it('(darkness 1) should swap palette after render with darker color (except for black)', function ()
      local pp = postprocess()
      pp.darkness = 1

      pp:apply()

      assert.spy(pal).was_called(15)
      assert.spy(pal).was_called_with(1, postprocess.swap_palette_by_darkness[1][1], 1)
      -- ...
      assert.spy(pal).was_called_with(15, postprocess.swap_palette_by_darkness[15][1], 1)
    end)

    it('(darkness 5) should clear screen', function ()
      local pp = postprocess()
      pp.darkness = 5

      pp:apply()

      assert.spy(cls).was_called(1)
      assert.spy(cls).was_called_with()
    end)

  end)

end)
