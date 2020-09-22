require("engine/test/bustedhelper")
local location_rect = require("engine/core/location_rect")

describe('location_rect', function ()

  describe('init', function ()
    it('should create a new tile vector with the right coordinates', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.are_same({0, 1, 10, 8}, {lrect.left, lrect.top, lrect.right, lrect.bottom})
    end)
  end)

  describe('_tostring', function ()
    it('should return a string representation with the boundaries', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.are_equal("location_rect(0, 1, 10, 8)", lrect:_tostring())
    end)
  end)

  describe('contains', function ()

    it('(0, 1, 10, 8) contains (0, 1)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_true(lrect:contains(location(0, 1)))
    end)

    it('(0, 1, 10, 8) contains (10, 1)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_true(lrect:contains(location(10, 1)))
    end)

    it('(0, 1, 10, 8) contains (0, 8)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_true(lrect:contains(location(0, 8)))
    end)

    it('(0, 1, 10, 8) contains (10, 8)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_true(lrect:contains(location(10, 8)))
    end)

    it('(0, 1, 10, 8) does not contain (-1, 1)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(-1, 1)))
    end)

    it('(0, 1, 10, 8) does not contain (0, 0)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(0, 0)))
    end)

    it('(0, 1, 10, 8) does not contain (11, 1)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(11, 1)))
    end)

    it('(0, 1, 10, 8) does not contain (10, 0)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(10, 0)))
    end)

    it('(0, 1, 10, 8) does not contain (-1, 8)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(-1, 8)))
    end)

    it('(0, 1, 10, 8) does not contain (0, 9)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(0, 9)))
    end)

    it('(0, 1, 10, 8) does not contain (11, 8)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(11, 8)))
    end)

    it('(0, 1, 10, 8) does not contain (10, 9)', function ()
      local lrect = location_rect(0, 1, 10, 8)
      assert.is_false(lrect:contains(location(10, 9)))
    end)

  end)

end)
