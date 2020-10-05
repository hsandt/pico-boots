require("engine/test/bustedhelper")
local graphics_helper = require("engine/ui/graphics_helper")

describe('draw_box', function ()

  setup(function ()
    stub(_G, "rect")
    stub(_G, "rectfill")
  end)

  teardown(function ()
    rect:revert()
    rectfill:revert()
  end)

  after_each(function ()
    rect:clear()
    rectfill:clear()
  end)

  it('should draw a rect for the frame', function ()
    graphics_helper.draw_box(10, 20, 40, 50, colors.black, colors.blue)

    local s = assert.spy(rect)
    s.was_called(1)
    s.was_called_with(10, 20, 40, 50, colors.black)
  end)

  it('should fill a rect with padding 1px for the background', function ()
    graphics_helper.draw_box(10, 20, 40, 50, colors.black, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(1)
    s.was_called_with(11, 21, 39, 49, colors.blue)
  end)

  it('should fill a rect with padding 1px, supporting bottom and right coord first', function ()
    graphics_helper.draw_box(40, 50, 10, 20, colors.black, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(1)
    s.was_called_with(11, 21, 39, 49, colors.blue)
  end)

  it('should not fill a rect with padding 1px if box is too small', function ()
    graphics_helper.draw_box(10, 20, 40, 21, colors.black, colors.blue)

    local s = assert.spy(rectfill)
    s.was_not_called()
  end)

end)

describe('draw_rounded_box', function ()

  setup(function ()
    stub(_G, "line")
    stub(_G, "rectfill")
  end)

  teardown(function ()
    line:revert()
    rectfill:revert()
  end)

  after_each(function ()
    line:clear()
    rectfill:clear()
  end)

  it('should draw a rect with 1px cut corners for the frame', function ()
    graphics_helper.draw_rounded_box(10, 20, 40, 50, colors.black, colors.blue)

    local s = assert.spy(line)
    s.was_called(4)
    s.was_called_with(11, 20, 39, 20, colors.black)
    s.was_called_with(40, 21, 40, 49, colors.black)
    s.was_called_with(39, 50, 11, 50, colors.black)
    s.was_called_with(10, 49, 10, 21, colors.black)
  end)

  it('should fill a rect with padding 1px for the background', function ()
    graphics_helper.draw_rounded_box(10, 20, 40, 50, colors.black, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(1)
    s.was_called_with(11, 21, 39, 49, colors.blue)
  end)

  it('should fill a rect with padding 1px, supporting bottom and right coord first', function ()
    graphics_helper.draw_rounded_box(40, 50, 10, 20, colors.black, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(1)
    s.was_called_with(11, 21, 39, 49, colors.blue)
  end)

  it('should not fill a rect with padding 1px if box is too small', function ()
    graphics_helper.draw_rounded_box(10, 20, 40, 21, colors.black, colors.blue)

    local s = assert.spy(rectfill)
    s.was_not_called()
  end)

end)

describe('draw_gauge', function ()

  setup(function ()
    stub(_G, "rect")
    stub(_G, "rectfill")
  end)

  teardown(function ()
    rect:revert()
    rectfill:revert()
  end)

  after_each(function ()
    rect:clear()
    rectfill:clear()
  end)

  it('should draw a rect for the frame', function ()
    graphics_helper.draw_gauge(10, 20, 40, 50, 0, directions.right, colors.black, colors.white, colors.blue)

    local s = assert.spy(rect)
    s.was_called(1)
    s.was_called_with(10, 20, 40, 50, colors.black)
  end)

  it('should fill a rect with padding 1px for the background, but no extra fill if gauge is too small', function ()
    graphics_helper.draw_gauge(10, 20, 40, 50, 0, directions.right, colors.black, colors.white, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(1)
    s.was_called_with(11, 21, 39, 49, colors.white)
  end)

  it('should fill a rect with padding 1px, supporting bottom and right coord first, but no extra fill if gauge is too small', function ()
    graphics_helper.draw_gauge(40, 50, 10, 20, 0, directions.right, colors.black, colors.white, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(1)
    s.was_called_with(11, 21, 39, 49, colors.white)
  end)

  it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward right)', function ()
    graphics_helper.draw_gauge(10, 20, 41, 51, 0.5, directions.left, colors.black, colors.white, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(2)
    s.was_called_with(11, 21, 40, 50, colors.white)
    s.was_called_with(26, 21, 40, 50, colors.blue)
  end)

  it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward right)', function ()
    graphics_helper.draw_gauge(10, 20, 41, 51, 0.5, directions.right, colors.black, colors.white, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(2)
    s.was_called_with(11, 21, 40, 50, colors.white)
    s.was_called_with(11, 21, 25, 50, colors.blue)
  end)

  it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward down and inverted coords)', function ()
    graphics_helper.draw_gauge(61, 71, 50, 20, 0.5, directions.down, colors.black, colors.white, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(2)
    s.was_called_with(51, 21, 60, 70, colors.white)
    s.was_called_with(51, 21, 60, 45, colors.blue)
  end)

  it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward up and inverted coords)', function ()
    graphics_helper.draw_gauge(61, 71, 50, 20, 0.5, directions.up, colors.black, colors.white, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(2)
    s.was_called_with(51, 21, 60, 70, colors.white)
    s.was_called_with(51, 46, 60, 70, colors.blue)
  end)

  it('should fill a rect with padding 1px for the background, and full fill (toward down and inverted coords)', function ()
    graphics_helper.draw_gauge(61, 71, 50, 20, 1, directions.down, colors.black, colors.white, colors.blue)

    local s = assert.spy(rectfill)
    s.was_called(2)
    s.was_called_with(51, 21, 60, 70, colors.white)
    s.was_called_with(51, 21, 60, 70, colors.blue)
  end)

  it('should not rectfill at all if box is too small', function ()
    graphics_helper.draw_gauge(10, 20, 40, 21, 0, directions.right, colors.black, colors.white, colors.blue)

    assert.spy(rectfill).was_not_called()
  end)

end)
