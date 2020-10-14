require("engine/test/bustedhelper")
local outline = require("engine/ui/outline")

describe('outline', function ()

  setup(function ()
    stub(api, "print")
  end)

  teardown(function ()
    api.print:revert()
  end)

  after_each(function ()
    api.print:clear()
  end)

  describe('print_with_outline', function ()

    it('(no outline) should call print once', function ()
      outline.print_with_outline("great", 24, 68, colors.red)

      assert.spy(api.print).was_called(1)
      assert.spy(api.print).was_called_with("great", 24, 68, colors.red)
    end)

    it('(outline) should call print 4 times for outline and once for fill color', function ()
      outline.print_with_outline("great", 24, 68, colors.red, colors.green)

      assert.spy(api.print).was_called(5)

      assert.spy(api.print).was_called_with("great", 23, 68, colors.green)
      assert.spy(api.print).was_called_with("great", 25, 68, colors.green)
      assert.spy(api.print).was_called_with("great", 24, 67, colors.green)
      assert.spy(api.print).was_called_with("great", 24, 69, colors.green)

      assert.spy(api.print).was_called_with("great", 24, 68, colors.red)
    end)

  end)

end)
