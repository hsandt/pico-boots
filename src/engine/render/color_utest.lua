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

describe('color_to_bitmask', function ()

  it('should return low-endian bitmask with unique bit set to passed color index', function ()
    set_unique_transparency(12)
    -- 0b pattern not recognized by native Lua, so use hexadecimal: 0b0000000000000010 -> 0x2
    assert.are_equal(0x2, color_to_bitmask(14))
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
