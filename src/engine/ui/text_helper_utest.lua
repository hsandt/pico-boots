require("engine/test/bustedhelper")
local text_helper = require("engine/ui/text_helper")
local outline = require("engine/ui/outline")

describe('wwrap', function ()

  local wwrap = text_helper.wwrap

  -- bugfix history: +
  it('wwrap("hello", 5) => "hello"', function ()
    assert.are_equal("hello", wwrap("hello", 5))
  end)
  -- bugfix history: +
  it('wwrap("hello world", 5) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello world", 5))
  end)
  -- bugfix history: +
  it('wwrap("hello world", 10) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello world", 10))
  end)
  it('wwrap("hello world", 11) => "hello world"', function ()
    assert.are_equal("hello world", wwrap("hello world", 11))
  end)
  -- bugfix history: +
  it('wwrap("toolongfromthestart", 5) => "toolongfromthestart" (we can\'t warp at all, give up)', function ()
    assert.are_equal("toolongfromthestart", wwrap("toolongfromthestart", 5))
  end)
  it('wwrap("toolongfromthestart this is okay", 5) => "toolongfromthestart\nthis\nis\nokay" (we can\'t warp at all, give up)', function ()
    assert.are_equal("toolongfromthestart\nthis\nis\nokay", wwrap("toolongfromthestart this is okay", 5))
  end)
  it('wwrap("hello\nworld", 5) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello\nworld", 5))
  end)
  it('wwrap("hello\n\nworld", 5) => "hello\n\nworld"', function ()
    assert.are_equal("hello\n\nworld", wwrap("hello\n\nworld", 5))
  end)
  it('wwrap("hello world\nhow are you today?", 8) => "hello\nworld\nhow are\nyou\ntoday?"', function ()
    assert.are_equal("hello\nworld\nhow are\nyou\ntoday?", wwrap("hello world\nhow are you today?", 8))
  end)
  it('wwrap("short\ntoolongfromthestart\nshort again", 8) => "short\ntoolongfromthestart\nshort\nagain"', function ()
    assert.are_equal("short\ntoolongfromthestart\nshort\nagain", wwrap("short\ntoolongfromthestart\nshort again", 8))
  end)
end)

describe('compute_single_line_text_width', function ()

  after_each(function ()
    clear_table(pico8.poked_addresses)
  end)

  it('should return the number of characters * standard char width by default', function ()
    assert.are_equal(5 * 4, text_helper.compute_single_line_text_width("hello"))
  end)

  it('should return the number of characters * custom font char width if use_custom_font is true', function ()
    -- set custom font char width
    poke(0x5600, 8)
    assert.are_equal(5 * 8, text_helper.compute_single_line_text_width("hello", true))
  end)

  it('should return the number of non-control characters * custom font char width if use_custom_font is true', function ()
    -- set custom font char width
    poke(0x5600, 8)
    assert.are_equal(5 * 8, text_helper.compute_single_line_text_width("\14hello", true))
  end)

  it('should count wide characters as double width', function ()
    assert.are_equal(5 * 4 + 1 * 8, text_helper.compute_single_line_text_width("hello\128"))
  end)

  it('should ignore valid control characters and consider custom font wide characters with width 2', function ()
    -- set custom font char widths
    poke(0x5600, 8)
    poke(0x5601, 16)
    assert.are_equal(5 * 8 + 1 * 16, text_helper.compute_single_line_text_width("\14hello\128", true))
  end)

  it('should ignore special command "\\^x[hex digit]" (override width doesn\'t change anything)', function ()
    assert.are_equal(5 * 4, text_helper.compute_single_line_text_width("\6x4hello"))
  end)

  it('should ignore special command "\\^x[hex digit]" (override width increase)', function ()
    assert.are_equal(5 * 5, text_helper.compute_single_line_text_width("\6x5hello"))
  end)

  it('should ignore special command "\\^x[hex digit] (custom font)" (override width doesn\'t change anything)', function ()
    -- set custom font char widths
    poke(0x5600, 8)
    poke(0x5601, 16)
    assert.are_equal(5 * 8 + 1 * 16, text_helper.compute_single_line_text_width("\14\6x8hello\128", true))
  end)

  it('should ignore special command "\\^x[hex digit] (custom font)" (override width increase)', function ()
    -- set custom font char widths
    poke(0x5600, 8)
    poke(0x5601, 16)
    -- note how the increase in width affects both standard and wide characters
    assert.are_equal(5 * 9 + 1 * 17, text_helper.compute_single_line_text_width("\14\6x9hello\128", true))
  end)

  it('should error on unsupported control character', function ()
    assert.has_error(function ()
      text_helper.compute_single_line_text_width("\15hello")
    end)
  end)

  it('should error on "\\^[non supported special command char]" control character', function ()
    assert.has_error(function ()
      -- native Lua only recognizes \6 instead of \^, but it's the same
      text_helper.compute_single_line_text_width("\6y")
    end)
  end)

  it('should error on "\\^x[non hex digit]" control character', function ()
    assert.has_error(function ()
      -- native Lua only recognizes \6 instead of \^, but it's the same
      text_helper.compute_single_line_text_width("\6x_")
    end)
  end)

end)

describe('compute_char_height', function ()

  after_each(function ()
    clear_table(pico8.poked_addresses)
  end)

  it('should return standard char height by default', function ()
    assert.are_equal(6, text_helper.compute_char_height())
  end)

  it('should return custom font char height if use_custom_font is true', function ()
    -- set custom font char height
    poke(0x5602, 8)
    assert.are_equal(8, text_helper.compute_char_height(true))
  end)

end)

describe('compute_text_height', function ()

  after_each(function ()
    clear_table(pico8.poked_addresses)
  end)

  it('should return standard char height for empty text', function ()
    assert.are_equal(6, text_helper.compute_text_height(""))
  end)

  it('should return custom font char height for empty text if use_custom_font is true', function ()
    -- set custom font char height
    poke(0x5602, 8)
    assert.are_equal(8, text_helper.compute_text_height("", true))
  end)

  it('should return standard char height for single-line text', function ()
    assert.are_equal(6, text_helper.compute_text_height("hello"))
  end)

  it('should return custom font char height for single-line text if use_custom_font is true', function ()
    -- set custom font char height
    poke(0x5602, 8)
    assert.are_equal(8, text_helper.compute_text_height("hello", true))
  end)

  it('should return standard char height * #lines for multi-line text', function ()
    assert.are_equal(6 * 2, text_helper.compute_text_height("hello\nworld"))
  end)

  it('should return custom font char height * #lines for multi-line text if use_custom_font is true', function ()
    -- set custom font char height
    poke(0x5602, 8)
    assert.are_equal(8 * 2, text_helper.compute_text_height("hello\nworld", true))
  end)

end)

describe('single_line_center_x_to_left', function ()

  after_each(function ()
    clear_table(pico8.poked_addresses)
  end)

  it('should return the position minus the text half-width + offset 1', function ()
    assert.are_equal(3, text_helper.single_line_center_x_to_left("hello", 12))
  end)

  it('should return the position minus the custom font text half-width + offset 1', function ()
    -- set custom font char height
    poke(0x5600, 8)
    assert.are_equal(-7, text_helper.single_line_center_x_to_left("hello", 12, true))
  end)

end)

describe('single_line_center_y_to_top', function ()

  after_each(function ()
    clear_table(pico8.poked_addresses)
  end)

  it('should return the position minus the text half-height + offset 1', function ()
    assert.are_equal(43, text_helper.single_line_center_y_to_top(45))
  end)

  it('should return the position minus the custom font text half-height + offset 1', function ()
    -- set custom font char height
    poke(0x5602, 8)
    assert.are_equal(42, text_helper.single_line_center_y_to_top(45, true))
  end)

end)

describe('single_line_center_to_topleft', function ()

  after_each(function ()
    clear_table(pico8.poked_addresses)
  end)

  it('should return the position minus the text half-size + offset (1, 1)', function ()
    assert.are_same({3, 43}, {text_helper.single_line_center_to_topleft("hello", 12, 45)})
  end)

  it('should return the position minus the custom font text half-size + offset (1, 1)', function ()
    -- set custom font char width & height
    poke(0x5600, 8)
    poke(0x5602, 8)
    assert.are_same({-7, 42}, {text_helper.single_line_center_to_topleft("hello", 12, 45, true)})
  end)

end)

describe('print_aligned', function ()

  setup(function ()
    stub(outline, "print_with_outline")
    -- exceptionally, do not stub single_line_center_to_topleft
    --   and similar helpers, as we want the values
    --   to still be meaningful

    -- set custom font char width & height
    poke(0x5600, 8)
    poke(0x5602, 8)
  end)

  teardown(function ()
    outline.print_with_outline:revert()

    clear_table(pico8.poked_addresses)
  end)

  after_each(function ()
    outline.print_with_outline:clear()
  end)

  it('should print text centered with horizontal center alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.horizontal_center, colors.blue, colors.yellow)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", 13, 45, colors.blue, colors.yellow)
  end)

  it('should print custom font text centered with horizontal center alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.horizontal_center, colors.blue, colors.yellow, true)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", 3, 45, colors.blue, colors.yellow)
  end)

  it('should print text centered with center alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.center, colors.blue)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", 13, 43, colors.blue, nil)
  end)

  it('should print custom font text centered with center alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.center, colors.blue, nil, true)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", 3, 42, colors.blue, nil)
  end)

  it('should print multi-line text line by line with center alignment', function ()
    text_helper.print_aligned("hello\nworld!", 12, 45, alignments.center, colors.blue)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(2)
    s.was_called_with("hello", 3, 40, colors.blue, nil)
    s.was_called_with("world!", 1, 46, colors.blue, nil)
  end)

  it('should print multi-line text line by line with center alignment, using extra line spacing', function ()
    text_helper.print_aligned("hello\nworld!", 12, 45, alignments.center, colors.blue, nil, false, 7)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(2)
    s.was_called_with("hello", 3, 40, colors.blue, nil)
    s.was_called_with("world!", 1, 46 + 7, colors.blue, nil)
  end)

  it('should print multi-line custom font text line by line with center alignment', function ()
    -- set custom font char width & height
    poke(0x5600, 8)
    poke(0x5602, 8)

    text_helper.print_aligned("hello\nworld!", 12, 45, alignments.center, colors.blue, nil, true)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(2)
    s.was_called_with("hello", -7, 38, colors.blue, nil)
    s.was_called_with("world!", -11, 46, colors.blue, nil)
  end)

  it('should print text from the left with left alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.left, colors.blue)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", 22, 45, colors.blue, nil)
  end)

  it('should print custom font text from the left with left alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.left, colors.blue, nil, true)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", 22, 45, colors.blue, nil)
  end)

  it('should print text from the right with right alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.right, colors.blue)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", 3, 45, colors.blue, nil)
  end)

  it('should print custom font text from the right with right alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.right, colors.blue, nil, true)

    local s = assert.spy(outline.print_with_outline)
    s.was_called(1)
    s.was_called_with("hello", -17, 45, colors.blue, nil)
  end)

end)
