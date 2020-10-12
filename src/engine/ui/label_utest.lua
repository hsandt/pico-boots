require("engine/test/bustedhelper")
local label = require("engine/ui/label")

describe('label', function ()

  describe('init', function ()

    it('should init label with layer', function ()
      local lab = label("great", vector(24, 68), colors.red, colors.yellow)
      assert.are_same({"great", vector(24, 68), colors.red, colors.yellow}, {lab.text, lab.position, lab.colour, lab.outline_colour})
    end)

  end)

  describe('_tostring', function ()

    it('should return "label(\'[text]\' @ [position] in [colour] outlined [outline_colour])"', function ()
      assert.are_equal("label('good' @ vector(22, 62) in yellow outlined none)", label("good", vector(22, 62), colors.yellow + 16):_tostring())
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(api, "print")
    end)

    teardown(function ()
      api.print:revert()
    end)

    after_each(function ()
      api.print:clear()
    end)

    it('(no outline) should call print once', function ()
      local lab = label("great", vector(24, 68), colors.red)

      lab:draw()

      local s = assert.spy(api.print)
      s.was_called(1)
      s.was_called_with("great", 24, 68, colors.red)
    end)

    it('(outline) should call print 4 times for outline and once for fill color', function ()
      local lab = label("great", vector(24, 68), colors.red, colors.green)

      lab:draw()

      local s = assert.spy(api.print)
      s.was_called(5)

      s.was_called_with("great", 23, 68, colors.green)
      s.was_called_with("great", 25, 68, colors.green)
      s.was_called_with("great", 24, 67, colors.green)
      s.was_called_with("great", 24, 69, colors.green)

      s.was_called_with("great", 24, 68, colors.red)
    end)

  end)

end)
