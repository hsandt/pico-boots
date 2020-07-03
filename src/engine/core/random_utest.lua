require("engine/test/bustedhelper")
require("engine/core/random")

describe('random_int_range_exc', function ()

  it('should assert when range <= 0', function ()
    assert.has_error(function ()
      random_int_range_exc(0)
    end)
  end)

  it('should return 0 when range == 1', function ()
    assert.are_equal(0, random_int_range_exc(1))
  end)

  -- testing a random function is hard, so stub rnd
  -- with the two extreme cases

  describe('(rnd(x) returns 0)', function ()

    setup(function ()
      stub(_G, "rnd", function (x)
        return 0
      end)
    end)

    teardown(function ()
      rnd:revert()
    end)

    it('should return 0', function ()
      assert.are_equal(0, random_int_range_exc(10))
    end)

  end)

  describe('(rnd(x) returns x - 0.001)', function ()

    setup(function ()
      stub(_G, "rnd", function (x)
        return x - 0.001
      end)
    end)

    teardown(function ()
      rnd:revert()
    end)

    it('should return range - 1', function ()
      assert.are_equal(9, random_int_range_exc(10))
    end)

  end)

end)

describe('random_int_bounds_inc', function ()

  it('should assert when lower > upper', function ()
    assert.has_error(function ()
      random_int_bounds_inc(5, 4)
    end)
  end)

  it('should return lower when lower == upper', function ()
    assert.are_equal(6, random_int_bounds_inc(6, 6))
  end)

  -- testing a random function is hard, so stub rnd
  -- with the two extreme cases

  describe('(rnd(x) returns 0)', function ()

    setup(function ()
      stub(_G, "rnd", function (x)
        return 0
      end)
    end)

    teardown(function ()
      rnd:revert()
    end)

    it('should return lower', function ()
      assert.are_equal(5, random_int_bounds_inc(5, 10))
    end)

  end)

  describe('(rnd(x) returns x - 0.001)', function ()

    setup(function ()
      stub(_G, "rnd", function (x)
        return x - 0.001
      end)
    end)

    teardown(function ()
      rnd:revert()
    end)

    it('should return upper', function ()
      assert.are_equal(10, random_int_bounds_inc(5, 10))
    end)

  end)

end)

describe('pick_random', function ()

  it('should assert if the table is empty', function ()
    assert.has_error(function ()
      pick_random({})
    end)
  end)

  it('should return the single table element if of length 1', function ()
    local t = {}
    assert.are_equal(t, pick_random({t}))
  end)

  -- testing a random function is hard, so stub rnd
  -- with the two extreme cases

  describe('(random_int_bounds_inc returns lower bound)', function ()

    setup(function ()
      stub(math, "random", function (upper)
        return 1
      end)
    end)

    teardown(function ()
      math.random:revert()
    end)

    it('should return the first element', function ()
      local t = {99}
      assert.are_equal(t, pick_random({t, {}, {}}))
    end)

  end)

  describe('(random_int_bounds_inc returns upper bound)', function ()

    setup(function ()
      stub(math, "random", function (upper)
        return upper
      end)
    end)

    teardown(function ()
      math.random:revert()
    end)

    it('should return the last element', function ()
      local t = {99}
      assert.are_equal(t, pick_random({{}, {}, t}))
    end)

  end)

end)
