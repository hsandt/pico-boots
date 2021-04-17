require("engine/test/bustedhelper")
require("engine/core/angle")

describe('compute_signed_angle_between', function ()
  it('0.25, 0.5 => 0.25', function ()
    assert.are_equal(0.25, compute_signed_angle_between(0.25, 0.5))
  end)
  it('0.25, 0.75 => -0.5', function ()
    assert.are_equal(-0.5, compute_signed_angle_between(0.25, 0.75))
  end)
  it('0.1, 0.9 => -0.2', function ()
    -- native lua has some float imprecisions
    assert.is_true(almost_eq_with_message(-0.2, compute_signed_angle_between(0.1, 0.9)))
  end)
  it('0, 0.9 => -0.1', function ()
    -- native lua has some float imprecisions
    assert.is_true(almost_eq_with_message(-0.1, compute_signed_angle_between(0, 0.9)))
  end)

  -- now oppose the order of angles above
  it('0.5, 0.25 => -0.25', function ()
    assert.are_equal(-0.25, compute_signed_angle_between(0.5, 0.25))
  end)
  it('0.75, 0.25 => -0.5', function ()
    -- 0.5 maps to -0.5, so don't opposite sign for this difference
    assert.are_equal(-0.5, compute_signed_angle_between(0.75, 0.25))
  end)
  it('0.9, 0.1 => 0.2', function ()
    -- native lua has some float imprecisions
    assert.is_true(almost_eq_with_message(0.2, compute_signed_angle_between(0.9, 0.1)))
  end)
  it('0.9, 0 => 0.1', function ()
    -- native lua has some float imprecisions
    assert.is_true(almost_eq_with_message(0.1, compute_signed_angle_between(0.9, 0)))
  end)
end)
