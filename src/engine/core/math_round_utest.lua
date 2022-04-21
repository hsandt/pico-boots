require("engine/test/bustedhelper")
require("engine/core/math_round")

describe('round', function ()

  it('round(0) => 0', function ()
    assert.are_equal(0, round(0))
  end)

  it('round(0.99) => 1', function ()
    assert.are_equal(1, round(0.99))
  end)

  it('round(5.5) => 6', function ()
    assert.are_equal(6, round(5.5))
  end)

  it('round(-5.5) => -6', function ()
    assert.are_equal(-6, round(-5.5))
  end)

  it('round(0, 0) => 0', function ()
    assert.are_equal(0, round(0, 0))
  end)

  it('round(5.5, 0) => 6', function ()
    assert.are_equal(6, round(5.5, 0))
  end)

  it('round(-5.5, 0) => -6', function ()
    assert.are_equal(-6, round(-5.5, 0))
  end)

  it('round(0, 2) => 0', function ()
    assert.are_equal(0, round(0, 2))
  end)

  it('round(0.99, 1) => 1', function ()
    assert.are_equal(1, round(0.99, 1))
  end)

  it('round(2.35, 1) => 2.4', function ()
    assert.are_equal(2.4, round(2.35, 1))
  end)

  it('round(-2.35, 1) => -2.4', function ()
    assert.are_equal(-2.4, round(-2.35, 1))
  end)

  it('round(0.994, 2) => 0.99', function ()
    assert.are_equal(0.99, round(0.994, 2))
  end)

  it('round(0.995, 2) => 1', function ()
    assert.are_equal(1, round(0.995, 2))
  end)

  -- while rounding 5.1 at two decimals seems easy, remember that PICO-8
  --  stores numbers with fixed power of two precision, so even a perfect decimal
  --  like 5.1 may actually not be perfect, and represented as 5.09 if flooring
  --  so this effectively verifies that our rounding is working

  it('round(5.1, 2) => 5.1', function ()
    assert.are_equal(5.1, round(5.1, 2))
  end)

  it('round(-5.1, 2) => -5.1', function ()
    assert.are_equal(-5.1, round(-5.1, 2))
  end)

end)
