require("engine/test/bustedhelper")
require("engine/render/sprite")

describe('spr_r', function ()

  -- todo: define pixel matrix simulating pico8 screen

  setup(function ()
    stub(_G, "sget", function ()
      -- todo: get color from pixel matrix
    end)
    stub(_G, "pset", function ()
      -- todo: set color on pixel matrix
    end)
  end)

  teardown(function ()
    sget:revert()
    pset:revert()
  end)

  after_each(function ()
    sget:clear()
    pset:clear()
  end)

  it('should draw a sprite as the original when angle is 0', function ()
    -- todo: call spr_r and check pixel matrix
  end)

  it('should draw a sprite rotated around pivot by 90 degrees counter-clockwise when angle is 0.25', function ()
    -- todo: call spr_r and check pixel matrix
  end)

  it('should draw a sprite flipped horizontally around pivot when flip_x is true', function ()
    -- todo: call spr_r and check pixel matrix
  end)

  it('should draw a sprite flipped vertically around pivot when flip_y is true', function ()
    -- todo: call spr_r and check pixel matrix
  end)

  it('should draw a sprite flipped horizontally and rotated around pivot by 90 degrees clockwise when flip_x is true and angle is 0.75', function ()
    -- todo: call spr_r and check pixel matrix
  end)

end)
