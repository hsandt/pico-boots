require("engine/test/bustedhelper")
require("engine/core/vector_ext")  -- already in engine/common, but added for clarity

describe('unit_from_angle', function ()
  it('(vector.unit_from_angle(0) => 0', function ()
    assert.are_equal(vector(1, 0), vector.unit_from_angle(0))
  end)
  it('vector.unit_from_angle(0.125) => (1/sqrt(2), -1/sqrt(2))', function ()
    assert.is_true(almost_eq_with_message(vector(1/sqrt(2), -1/sqrt(2)), vector.unit_from_angle(0.125)))
  end)
  it('vector.unit_from_angle(0.25) => vector(0, -1)', function ()
    assert.is_true(almost_eq_with_message(vector(0, -1), vector.unit_from_angle(0.25)))
  end)
  it('vector.unit_from_angle(0.5) => vector(-1, 0)', function ()
    assert.is_true(almost_eq_with_message(vector(-1, 0), vector.unit_from_angle(0.5)))
  end)
  it('vector.unit_from_angle(-60/360) => vector(0.5, sqrt(3)/2)', function ()
    assert.is_true(almost_eq_with_message(vector(0.5, sqrt(3)/2), vector.unit_from_angle(-1/6)))
  end)
end)

describe('dot', function ()
  it('(1 -1) dot (1 1) => 0', function ()
    assert.are_equal(0, vector(1, -1):dot(vector(1, 1)))
  end)
  it('(2 0) dot (-1 1) => 0', function ()
    assert.are_equal(-2, vector(2, 0):dot(vector(-1, 1)))
  end)
  it('(0 -4) dot (-1 -2) => 0', function ()
    assert.are_equal(8, vector(0, -4):dot(vector(-1, -2)))
  end)
  it('(2 -4) dot (-1 -2) => 0', function ()
    assert.are_equal(6, vector(2, -4):dot(vector(-1, -2)))
  end)
end)

describe('sqr_magnitude', function ()
  it('(4 3) => 25', function ()
    assert.are_equal(25, vector(4, 3):sqr_magnitude())
  end)
  it('(-4 3) => 25', function ()
    assert.are_equal(25, vector(-4, 3):sqr_magnitude())
  end)
  it('(9 -14.2) => 282.64', function ()
    assert.is_true(almost_eq(vector(9, -14.2):sqr_magnitude(), 282.64))
  end)
  it('(0 0) => 0', function ()
    assert.are_equal(0, vector.zero():sqr_magnitude())
  end)
end)

describe('magnitude', function ()
  it('(4 3) => 5', function ()
    assert.is_true(almost_eq(vector(4, 3):magnitude(), 5))
  end)
  it('(-4 3) => 5', function ()
    assert.is_true(almost_eq(vector(-4, 3):magnitude(), 5))
  end)
  it('(9 -14.2) => 16.811900547', function ()
    assert.is_true(almost_eq(vector(9, -14.2):magnitude(), 16.811900547))
  end)
  it('(0 0) => 0', function ()
    assert.are_equal(0, vector.zero():magnitude())
  end)
end)

describe('normalized', function ()
  it('(1 -1) => (0.707... -0.707...)', function ()
    assert.is_true(vector(1, -1):normalized():almost_eq(vector(0.707, -0.707)))
  end)
  it('(4 3) => (0.8 0.6)', function ()
    assert.is_true(vector(4, 3):normalized():almost_eq(vector(0.8, 0.6)))
  end)
  it('(0.00004 0.00003) => (0.8 0.6)', function ()
    assert.is_true(vector(0.00004, 0.00003):normalized():almost_eq(vector(0.8, 0.6)))
  end)
  it('(0 0) => (0 0)', function ()
    local vec = vector.zero()
    local normalized_vec = vec:normalized()
    assert.is_true(normalized_vec:almost_eq(vector.zero()))
    -- check that a copy of the vector is returned, not the same ref
    assert.is_false(rawequal(normalized_vec, vec))
  end)
end)

describe('normalize', function ()
  it('(1 -1) => (0.707... -0.707...) in place', function ()
    local v = vector(1, -1)
    v:normalize()
    assert.is_true(v:almost_eq(vector(0.707, -0.707)))
  end)
  it('(4 3) => (0.8 0.6) in place', function ()
    local v = vector(4, 3)
    v:normalize()
    assert.is_true(v:almost_eq(vector(0.8, 0.6)))
  end)
  it('(0 0) => (0 0) in place', function ()
    local v = vector(0, 0)
    v:normalize()
    assert.are_equal(vector(0, 0), v)
  end)
end)

describe('with_clamped_magnitude', function ()
  it('(1 -1).with_clamped_magnitude(1) => (0.707... -0.707...)', function ()
    assert.is_true(vector(1, -1):with_clamped_magnitude(1):almost_eq(vector(0.707, -0.707)))
  end)
  it('(4 3).with_clamped_magnitude(5) => (4 3)', function ()
    local vec = vector(4, 3)
    local clamped_vec = vec:with_clamped_magnitude(5)
    assert.are_equal(clamped_vec, vector(4, 3))
    -- check that a copy of the vector is returned, not the same ref
    assert.is_false(rawequal(clamped_vec, vec))
  end)
  it('(4 3).with_clamped_magnitude(0) => (0 0)', function ()
    assert.is_true(vector(4, 3):with_clamped_magnitude(0):almost_eq(vector(0, 0)))
  end)
  it('(0 0).with_clamped_magnitude(5) => (0 0)', function ()
    assert.is_true(vector(0, 0):with_clamped_magnitude(5):almost_eq(vector(0, 0)))
  end)
  it('(0 0).with_clamped_magnitude(0) => (0 0)', function ()
    assert.is_true(vector(0, 0):with_clamped_magnitude(0):almost_eq(vector(0, 0)))
  end)
  it('(4 3).with_clamped_magnitude(-10) => (4 3)', function ()
    assert.has_error(function()
      vector(4, 3):with_clamped_magnitude(-10)
    end)
  end)
end)

describe('clamp_magnitude', function ()
  it('(4 -3).clamp_magnitude(2) => (1.6 -1.2)', function ()
    local v = vector(4, -3)
    v:clamp_magnitude(2)
    assert.is_true(v:almost_eq(vector(1.6, -1.2)))
  end)
  it('(4 3).clamp_magnitude(10) => (4 3)', function ()
    local v = vector(4, 3)
    v:clamp_magnitude(10)
    assert.is_true(v:almost_eq(vector(4, 3)))
  end)
  it('(4 3).clamp_magnitude(5) => (4 3)', function ()
    local v = vector(4, 3)
    v:clamp_magnitude(5)
    assert.is_true(v:almost_eq(vector(4, 3)))
  end)
  it('(4 3).clamp_magnitude(0) => (0 0)', function ()
    local v = vector(4, 3)
    v:clamp_magnitude(0)
    assert.is_true(v:almost_eq(vector(0, 0)))
  end)
  it('(0 0).clamp_magnitude(5) => (0 0)', function ()
    local v = vector(0, -0)
    v:clamp_magnitude(5)
    assert.is_true(v:almost_eq(vector(0, 0)))
  end)
end)

describe('with_clamped_magnitude_cardinal', function ()
  it('(1 -1).with_clamped_magnitude_cardinal(1) => (1 -1)', function ()
    local vec = vector(1, -1)
    local clamped_vec = vec:with_clamped_magnitude_cardinal(1)
    assert.are_equal(clamped_vec, vector(1, -1))
    -- check that a copy of the vector is returned, not the same ref
    assert.is_false(rawequal(clamped_vec, vec))
  end)
  it('(4 -3).with_clamped_magnitude_cardinal(2) => (2 -2)', function ()
    assert.is_true(vector(4, -3):with_clamped_magnitude_cardinal(2):almost_eq(vector(2, -2)))
  end)
  it('(-4 2).with_clamped_magnitude_cardinal(3) => (-3 3)', function ()
    assert.is_true(vector(-4, 2):with_clamped_magnitude_cardinal(3):almost_eq(vector(-3, 2)))
  end)
  it('(4 -8).with_clamped_magnitude_cardinal(3 5) => (3 -5)', function ()
    assert.is_true(vector(4, -8):with_clamped_magnitude_cardinal(3, 5):almost_eq(vector(3, -5)))
  end)
  it('(0 0).with_clamped_magnitude_cardinal(5) => (0 0)', function ()
    local vec = vector(0, 0)
    local clamped_vec = vec:with_clamped_magnitude_cardinal(5)
    assert.are_equal(clamped_vec, vector(0, 0))
    -- check that a copy of the vector is returned, not the same ref
    assert.is_false(rawequal(clamped_vec, vec))
  end)
end)

describe('clamp_magnitude_cardinal', function ()
  it('(4 -3).clamp_magnitude_cardinal(2 6) => (2, -3)', function ()
    local v = vector(4, -3)
    v:clamp_magnitude_cardinal(2, 6)
    assert.is_true(v:almost_eq(vector(2, -3)))
  end)
  it('(4 3).clamp_magnitude_cardinal(10) => (4 3)', function ()
    local v = vector(4, 3)
    v:clamp_magnitude_cardinal(10)
    assert.is_true(v:almost_eq(vector(4, 3)))
  end)
  it('(-4 3).clamp_magnitude_cardinal(5 1) => (-4 1)', function ()
    local v = vector(-4, 3)
    v:clamp_magnitude_cardinal(5, 1)
    assert.is_true(v:almost_eq(vector(-4, 1)))
  end)
  it('(-4 -3).clamp_magnitude_cardinal(2) => (-2 -2)', function ()
    local v = vector(-4, -3)
    v:clamp_magnitude_cardinal(2)
    assert.is_true(v:almost_eq(vector(-2, -2)))
  end)
  it('(0 0).clamp_magnitude_cardinal(5) => (0 0)', function ()
    local v = vector(0, 0)
    v:clamp_magnitude_cardinal(5)
    assert.is_true(v:almost_eq(vector(0, 0)))
  end)
end)

describe('mirrored_x', function ()
  it('(1 3).mirrored_x() => (-1, 3)', function ()
    assert.are_equal(vector(1, 3), vector(-1, 3):mirrored_x())
  end)
end)

describe('mirror_x', function ()
  it('(1 -3).mirror_x() => (-1, -3)', function ()
    local v = vector(1, -3)
    v:mirror_x()
    assert.are_equal(vector(-1, -3), v)
  end)
end)

describe('mirrored_y', function ()
  it('(1 3).mirrored_y() => (1, -3)', function ()
    assert.are_equal(vector(1, 3), vector(1, -3):mirrored_y())
  end)
end)

describe('mirror_y', function ()
  it('(1 -3).mirror_y() => (1, 3)', function ()
    local v = vector(1, -3)
    v:mirror_y()
    assert.are_equal(vector(1, 3), v)
  end)
end)

describe('rotated', function ()

  it('(1 -3).rotated(0) => (1 -3)', function ()
    assert.is_true(almost_eq_with_message(vector(1, -3), vector(1, -3):rotated(0)))
  end)

  it('(1 -3).rotated(0.125) => (-sqrt(2), - 2 * sqrt(2))', function ()
    assert.is_true(almost_eq_with_message(vector(-sqrt(2), - 2 * sqrt(2)), vector(1, -3):rotated(0.125)))
  end)

  it('(1 -3).rotated(0.25) => (1 -3).rotated_90_ccw = (-3, -1)', function ()
    assert.is_true(almost_eq_with_message(vector(-3, -1), vector(1, -3):rotated(0.25)))
  end)

  it('(1 -3).rotated(0.5) => (-1 3)', function ()
    assert.is_true(almost_eq_with_message(vector(-1, 3), vector(1, -3):rotated(0.5)))
  end)

  it('(1 -3).rotated(0.25) => (1 -3).rotated_90_cw = (3, 1)', function ()
    assert.is_true(almost_eq_with_message(vector(3, 1), vector(1, -3):rotated(-0.25)))
  end)

end)

-- bugfix history: ?
describe('rotated_90_cw', function ()
  it('(1 -3).rotated_90_cw() => (3, 1)', function ()
    assert.are_equal(vector(3, 1), vector(1, -3):rotated_90_cw())
  end)
end)

-- bugfix history: ?
describe('rotate_90_cw_inplace', function ()
  it('(1 -3).rotate_90_cw_inplace() => (3, 1)', function ()
    local v = vector(1, -3)
    v:rotate_90_cw_inplace()
    assert.are_equal(vector(3, 1), v)
  end)
end)

-- bugfix history: ?
describe('rotated_90_ccw', function ()
  it('(1 -3).rotated_90_ccw() => (-3, -1)', function ()
    assert.are_equal(vector(-3, -1), vector(1, -3):rotated_90_ccw())
  end)
end)

-- bugfix history: ?
describe('rotate_90_ccw_inplace', function ()
  it('(1 -3).rotate_90_ccw_inplace() => (-3, -1)', function ()
    local v = vector(1, -3)
    v:rotate_90_ccw_inplace()
    assert.are_equal(vector(-3, -1), v)
  end)
end)
