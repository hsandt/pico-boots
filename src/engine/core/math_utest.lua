require("engine/test/bustedhelper")
require("engine/core/math")  -- already in engine/common, but added for clarity

describe('almost_eq', function ()
  it('2.506 ~ 2.515', function ()
    assert.is_true(almost_eq(2.506, 2.515))
  end)
  it('2.505 ~! 2.516', function ()
    assert.is_false(almost_eq(2.505, 2.516))
  end)
  it('-5.984 ~ -5.9835 with eps=0.001', function ()
    assert.is_true(almost_eq(-5.984, -5.9835, 0.001))
  end)
  it('-5.984 !~ -5.9828 with eps=0.001', function ()
    assert.is_false(almost_eq(-5.984, -5.9828, 0.001))
  end)
  it('(-5.984, ) !~ -5.9828 with eps=0.001', function ()
    assert.is_false(almost_eq(-5.984, -5.9828, 0.001))
  end)

  it('vector(2.50501 5.8) ~ vector(2.515 5.79)', function ()
    assert.is_true(almost_eq(vector(2.50501, 5.8), vector(2.515, 5.79)))
  end)
  it('vector(2.505 5.8) !~ vector(2.515 5.788)', function ()
    assert.is_false(almost_eq(vector(2.505, 5.8), vector(2.515, 5.788)))
  end)
  it('vector(2.505 5.8) ~ vector(2.5049 5.799) with eps=0.001', function ()
    assert.is_true(almost_eq(vector(2.505, 5.8), vector(2.5049, 5.799), 0.001))
  end)
  it('vector(2.505 5.8) !~ vector(2.5047 5.789) with eps=0.001', function ()
    assert.is_false(almost_eq(vector(2.505, 5.8), vector(2.5047, 5.789), 0.001))
  end)

  it('should fail when comparing non-number, non-vector types', function ()
    assert.has_error(function ()
        almost_eq("text", 68)
      end,
      "almost_eq cannot compare text and 68")
  end)

end)

describe('tile_vector', function ()

  describe('_init', function ()
    it('should create a new tile vector with the right coordinates', function ()
      local loc = tile_vector(2, -6)
      assert.are_same({2, -6}, {loc.i, loc.j})
    end)
  end)

  describe('_tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local tile_vec = tile_vector(2, -6)
      assert.are_equal("tile_vector(2, -6)", tile_vec:_tostring())
    end)
  end)

  describe('to_topleft_position', function ()
    it('(1 2) => (8 16)', function ()
      assert.are_equal(vector(8, 16), location(1, 2):to_topleft_position())
    end)
  end)

end)

describe('sprite_id_location', function ()

  describe('_tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local sprite_id_loc = sprite_id_location(2, -6)
      assert.are_equal("sprite_id_location(2, -6)", sprite_id_loc:_tostring())
    end)
  end)

  describe('to_sprite_id', function ()
    it('(2 2) => 34', function ()
      assert.are_equal(34, sprite_id_location(2, 2):to_sprite_id())
    end)
    it('(15 1) => 31', function ()
      assert.are_equal(31, sprite_id_location(15, 1):to_sprite_id())
    end)
  end)

end)

describe('location', function ()

  describe('_tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local loc = location(2, -6)
      assert.are_equal("location(2, -6)", loc:_tostring())
    end)
  end)

  describe('to_center_position', function ()
    it('(1 2) => (12 20)', function ()
      assert.are_equal(vector(12, 20), location(1, 2):to_center_position())
    end)
  end)

end)

describe('vector', function ()

  describe('_init', function ()
    it('should create a new vector with the right coordinates', function ()
      local vec = vector(2, -6)
      assert.are_same({2, -6}, {vec.x, vec.y})
    end)
  end)

  describe('_tostring', function ()
    it('should return a string representation with the right coordinates', function ()
      local vec = vector(2, -6)
      assert.are_equal("vector(2, -6)", vec:_tostring())
    end)
  end)

  describe('get', function ()

    it('should return the x member when passing "x"', function ()
      local vec = vector(2, -6)
      assert.are_equal(2, vec:get("x"))
    end)

    it('should return the y member when passing "y"', function ()
      local vec = vector(2, -6)
      assert.are_equal(-6, vec:get("y"))
    end)

    it('should assert on coord being not "x" nor "y"', function ()
      assert.has_error(function ()
        vec:get("z")
      end)
    end)

  end)

  describe('set', function ()

    it('should set the x member to value when passing "x"', function ()
      local vec = vector(2, -6)
      vec:set("x", 8)
      assert.are_equal(8, vec.x)
    end)

    it('should set the y member to value when passing "y"', function ()
      local vec = vector(2, -6)
      vec:set("y", -4)
      assert.are_equal(-4, vec.y)
    end)

    it('should assert on coord being not "x" nor "y"', function ()
      assert.has_error(function ()
        vec:set("z", 0)
      end)
    end)

  end)

  describe('almost_eq', function ()
    it('vector(2.50501 5.8) ~ vector(2.515 5.79) (static version)', function ()
      -- due to precision issues, 2.505 !~ 2.515 with default eps=0.01!
      assert.is_true(vector.almost_eq(vector(2.50501, 5.8), vector(2.515, 5.79)))
    end)
    it('vector(2.50501 5.8) ~ vector(2.515 5.79)', function ()
      assert.is_true( vector(2.50501, 5.8):almost_eq(vector(2.515, 5.79)))
    end)
    it('vector(2.505 5.8) !~ vector(2.515 5.788)', function ()
      assert.is_false(vector(2.505, 5.8):almost_eq(vector(2.515, 5.788)))
    end)
    it('vector(2.505 5.8) ~ vector(2.5049 5.799) with eps=0.001', function ()
      assert.is_true( vector(2.505, 5.8):almost_eq(vector(2.5049, 5.799), 0.001))
    end)
    it('vector(2.505 5.8) !~ vector(2.5047 5.789) with eps=0.001', function ()
      assert.is_false(vector(2.505, 5.8):almost_eq(vector(2.5047, 5.789), 0.001))
    end)
  end)

  describe('__add', function ()
    it('(3 2) + (5 3) => (8 5)', function ()
      assert.are_equal(vector(8, 5), vector(3, 2) + vector(5, 3))
    end)
  end)

  describe('add_inplace', function ()
    it('(3 2):add_inplace((5 3)) => in-place (8 5)', function ()
      local v = vector(3, 2)
      v:add_inplace(vector(5, 3))
      assert.are_equal(vector(8, 5), v)
    end)
  end)

  describe('__sub', function ()
    it('(3 2) - (5 3) => (-2 -1)', function ()
      assert.are_equal(vector(-2, -1), vector(3, 2) - vector(5, 3))
    end)
  end)

  describe('sub_inplace', function ()
    it('(3 2):sub_inplace((5 3)) => in-place (-2 -1)', function ()
      local v = vector(3, 2)
      v:sub_inplace(vector(5, 3))
      assert.are_equal(vector(-2, -1), v)
    end)
  end)

  describe('__unm', function ()
    it('- (5 -3) => (-5 3)', function ()
      assert.are_equal(vector(-5, 3), - vector(5, -3))
    end)
  end)

  describe('__mul', function ()
    it('(3 2) * -2 => (-6 -4)', function ()
      assert.are_equal(vector(-6, -4), vector(3, 2) * -2)
    end)
    it('4 * (-3 2) => (-12 8)', function ()
      assert.are_equal(vector(-12, 8), 4 * vector(-3, 2))
    end)
    it('(-3 2) * (-12 8) => assert', function ()
      assert.has_error(function ()
          local _ = vector(-3, 2) * vector(-12, 8)
        end,
        "vector multiplication is only supported with a scalar, tried to multiply vector(-3, 2) and vector(-12, 8)")
    end)

    it('(3 2):mul_inplace(-2) => in-place (-6 -4)', function ()
      local v = vector(3, 2)
      v:mul_inplace(-2)
      assert.are_equal(vector(-6, -4), v)
    end)
    it('(-3 2):mul_inplace((-12 8)) => assert', function ()
      assert.has_error(function ()
          vector(-3, 2):mul_inplace(vector(-12, 8))
        end,
        "vector multiplication is only supported with a scalar, tried to multiply vector(-3, 2) and vector(-12, 8)")
    end)
  end)

  describe('__div', function ()
    it('(3, 2) / -2 => (-1.5, -1)', function ()
      assert.are_equal(vector(-1.5, -1), vector(3, 2) / -2)
    end)
    it('4 / (-3, 2) => assert', function ()
      assert.has_error(function ()
         local _ = 4 / vector(-3, 2)
        end,
        "vector division is only supported with a scalar as rhs, tried to multiply 4 and vector(-3, 2)")
    end)
    it('(-3 2) / (-3, 2) => assert', function ()
      assert.has_error(function ()
         local _ = vector(-3, 2) / vector(-3, 2)
        end,
        "vector division is only supported with a scalar as rhs, tried to multiply vector(-3, 2) and vector(-3, 2)")
    end)
    it('(-3 2) / 0 => assert', function ()
      assert.has_error(function ()
          local _ = vector(-3, 2) / 0
        end,
        "cannot divide vector vector(-3, 2) by zero")
    end)

    it('(3 2):div_inplace(-2) => in-place (-6 -4)', function ()
      local v = vector(3, 2)
      v:div_inplace(-2)
      assert.are_equal(vector(-1.5, -1), v)
    end)
    it('(-3 2):div_inplace(-3, 2) => assert', function ()
      assert.has_error(function ()
         local _ = vector(-3, 2):div_inplace(vector(-3, 2))
        end,
        "vector division is only supported with a scalar as rhs, tried to multiply vector(-3, 2) and vector(-3, 2)")
    end)
    it('(-3 2):div_inplace(0) => assert', function ()
      assert.has_error(function ()
          vector(-3, 2):div_inplace(0)
        end,
        "cannot divide vector vector(-3, 2) by zero")
    end)
  end)

  describe('zero()', function ()
    it('should be vector(0, 0)', function ()
      assert.are_equal(vector(0, 0), vector.zero())
    end)
    it('should be mutable', function ()
      local z = vector.zero()
      z.x = 5
      assert.are_equal(5, z.x)
    end)
  end)

  describe('to_location', function ()
    it('(12, -5) => (1, -1)', function ()
      local v = vector(12, -5)
      assert.are_equal(location(1, -1), v:to_location())
    end)
  end)

end)

describe('signed_speed_to_dir', function ()
  it('should -5 => left', function ()
    assert.are_equal(horizontal_dirs.left, signed_speed_to_dir(-5))
  end)
  it('should 2 => right', function ()
    assert.are_equal(horizontal_dirs.right, signed_speed_to_dir(2))
  end)
  it('should 0 => assert', function ()
    assert.has_error(function ()
      signed_speed_to_dir(0)
    end)
  end)
end)

describe('oppose_dir', function ()
  it('should left => right', function ()
    assert.are_equal(directions.right, oppose_dir(directions.left))
  end)
  it('should right => left', function ()
    assert.are_equal(directions.left, oppose_dir(directions.right))
  end)
  it('should up => down', function ()
    assert.are_equal(directions.down, oppose_dir(directions.up))
  end)
  it('should down => up', function ()
    assert.are_equal(directions.up, oppose_dir(directions.down))
  end)
end)
