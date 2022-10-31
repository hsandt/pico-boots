require("engine/test/bustedhelper")
local label = require("engine/ui/label")

local text_helper = require("engine/ui/text_helper")

describe('label', function ()

  describe('init', function ()

    it('should init label with layer', function ()
      local lab = label("great", vector(24, 68), alignments.left, colors.red, colors.yellow)
      assert.are_same({"great", vector(24, 68), alignments.left, colors.red, colors.yellow}, {lab.text, lab.position, lab.alignment, lab.colour, lab.outline_colour})
    end)

  end)

  describe('_tostring', function ()

    it('should return "label(\'[text]\' @ [position] in [colour] outlined [outline_colour])"', function ()
      assert.are_equal("label('good' @ vector(22, 62) aligned 1 in yellow outlined none, custom font: yes)", label("good", vector(22, 62), alignments.left, colors.yellow + 16, nil, true):_tostring())
    end)

    it('should return "label(\'[text]\' @ [position] in [colour] outlined [outline_colour])"', function ()
      assert.are_equal("label('good' @ vector(22, 62) aligned 1 in yellow outlined none, custom font: no)", label("good", vector(22, 62), alignments.left, colors.yellow + 16):_tostring())
    end)

  end)

  describe('draw', function ()

    setup(function ()
      stub(text_helper, "print_aligned")
    end)

    teardown(function ()
      text_helper.print_aligned:revert()
    end)

    after_each(function ()
      text_helper.print_aligned:clear()
    end)

    it('(no outline) should call print_aligned once without outline color (nil)', function ()
      local lab = label("great", vector(24, 68), alignments.left, colors.red)

      lab:draw()

      assert.spy(text_helper.print_aligned).was_called(1)
      assert.spy(text_helper.print_aligned).was_called_with("great", 24, 68, alignments.left, colors.red, nil, nil)
    end)

    it('(outline) should call print_aligned once with outline color and custom font', function ()
      local lab = label("great", vector(24, 68), alignments.right, colors.red, colors.green, true)

      lab:draw()

      assert.spy(text_helper.print_aligned).was_called(1)
      assert.spy(text_helper.print_aligned).was_called_with("great", 24, 68, alignments.right, colors.red, colors.green, true)
    end)

  end)

end)
