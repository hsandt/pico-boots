require("engine/test/bustedhelper")
require("engine/render/color")  -- already in engine/common, but added for clarity

describe('color_tostring', function ()

  it('should return the name of a known color by index', function ()
    assert.are_equal("dark_purple", color_tostring(2))
  end)

  it('should return the name of a known color by enum', function ()
    assert.are_equal("pink", color_tostring(colors.pink))
  end)

  it('should return "nil" for nil', function ()
    assert.are_equal("nil", color_tostring(nil))
  end)

  it('should return "peach" for -1', function ()
    assert.are_equal("peach", color_tostring(-1))
  end)

  it('should return "black" for 16', function ()
    assert.are_equal("black", color_tostring(16))
  end)

  it('should return "invalid color" for 0.1', function ()
    assert.are_equal("invalid color", color_tostring(0.1))
  end)

end)

describe('set_unique_transparency', function ()

  after_each(function ()
    -- reset transparency
    palt()
  end)

  it('should set the passed color as the unique transparent color', function ()
    set_unique_transparency(12)
    assert.are_same({
        [0] = false, false, false, false,
        false, false, false, false,
        false, false, false, false,
        true, false, false, false},
      pico8.pal_transparent
    )
  end)

end)
