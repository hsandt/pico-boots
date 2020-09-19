require("engine/test/bustedhelper")
local label = require("engine/ui/label")

describe('label', function ()

  describe('init', function ()

    it('should init label with layer', function ()
      local lab = label("great", vector(24, 68), colors.red)
      assert.are_same({"great", vector(24, 68), colors.red}, {lab.text, lab.position, lab.colour})
    end)

  end)

  describe('_tostring', function ()

    it('should return "label(\'[text]\' @ [position] in [colour])"', function ()
      assert.are_equal("label('good' @ vector(22, 62) in yellow)", label("good", vector(22, 62), colors.yellow):_tostring())
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(api, "print")
    end)

    teardown(function ()
      api.print:revert()
    end)

    it('should call print', function ()
      local lab = label("great", vector(24, 68), colors.red)

      lab:draw()

      local s = assert.spy(api.print)
      s.was_called(1)
      s.was_called_with("great", 24, 68, colors.red)
    end)

  end)

end)
