require("engine/test/bustedhelper")
local font_helper = require("engine/ui/font_helper")

describe('adjust_char_width', function ()

  local adjust_char_width = font_helper.adjust_char_width
  local to_custom_font_with_adjusted_char_width = font_helper.to_custom_font_with_adjusted_char_width

  -- Note that native Lua doesn't support \ followed by non-hexadecimal value,
  --  so for the utests, we exceptionally escape the \
  -- \14 is okay though, we just escape it in test descriptions to make it more readable

  it('adjust_char_width("hiya", 5) => "h\\^x2i\\^x6y\\^x4a!"', function ()
    assert.are_equal("h\6x2i\6x6y\6x4a!", adjust_char_width("hiya!", {["i"] = 2, ["y"] = 6}, 4))
  end)

  describe('to_custom_font_with_adjusted_char_width', function ()


    it('to_custom_font_with_adjusted_char_width("hiya!", 5) => "\\14h\\^x2i\\^x6y\\^x4a!"', function ()
      assert.are_equal("\14h\6x2i\6x6y\6x4a!", to_custom_font_with_adjusted_char_width("hiya!", {["i"] = 2, ["y"] = 6}, 4))
    end)

    it('to_custom_font_with_adjusted_char_width("hiya!\neveryone", 5) => "\\14h\\^x2i\\^x6y\\^x4a!\\14ever\\^x6y\\^x4one"', function ()
      assert.are_equal("\14h\6x2i\6x6y\6x4a!\n\14ever\6x6y\6x4one", to_custom_font_with_adjusted_char_width("hiya!\neveryone", {["i"] = 2, ["y"] = 6}, 4))
    end)

  end)

end)
