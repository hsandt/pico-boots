require("engine/test/bustedhelper")
local rectangle = require("engine/ui/rectangle")

describe('rectangle', function ()

  describe('init', function ()

    it('should init rectangle with parameters', function ()
      local my_rectangle = rectangle(vector(10, 20), 30, 40, colors.red)
      assert.are_same({vector(10, 20), 30, 40, colors.red}, {my_rectangle.position, my_rectangle.width, my_rectangle.height, my_rectangle.colour})
    end)

  end)

  describe('_tostring', function ()

    it('should return "rectangle(@ vector(10, 20), width: 30, height: 40, red)"', function ()
      assert.are_equal("rectangle(@ vector(10, 20), width: 30, height: 40, red)", rectangle(vector(10, 20), 30, 40, colors.red):_tostring())
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(_G, "rectfill")
    end)

    teardown(function ()
      rectfill:revert()
    end)

    after_each(function ()
      rectfill:clear()
    end)

    it('should call rectfill once', function ()
      -- mind width/height including the edge pixels, so +1 compared to x2-x1 and y2-y1
      -- passed to rectfill
      local my_rectangle = rectangle(vector(10, 20), 31, 41, colors.red)

      my_rectangle:draw()

      assert.spy(rectfill).was_called(1)
      assert.spy(rectfill).was_called_with(10, 20, 40, 60, colors.red)
    end)

  end)

end)
