require("engine/test/bustedhelper")
local text_helper = require("engine/ui/text_helper")

describe('wwrap', function ()
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

describe('center_x_to_left', function ()

  it('should return the position minus the text half-width + offset 1', function ()
    assert.are_equal(3, text_helper.center_x_to_left("hello", 12))
  end)

end)

describe('center_y_to_top', function ()

  it('should return the position minus the text half-height + offset 1', function ()
    assert.are_equal(43, text_helper.center_y_to_top("hello", 45))
  end)

end)

describe('center_to_topleft', function ()

  it('should return the position minus the text half-size + offset (1, 1)', function ()
    assert.are_same({3, 43}, {text_helper.center_to_topleft("hello", 12, 45)})
  end)

end)

describe('print_centered', function ()

  setup(function ()
    stub(api, "print")
  end)

  teardown(function ()
    api.print:revert()
  end)

  after_each(function ()
    api.print:clear()
  end)

  -- we didn't stub text_helper.print_centered, so we rely on print_centered being correct

  it('should print single-line text at position given by center_to_topleft', function ()
    text_helper.print_centered("hello", 12, 45, colors.blue)

    local s = assert.spy(api.print)
    s.was_called(1)
    s.was_called_with("hello", 3, 43, colors.blue)
  end)

  it('should print multi-line text line by line at positions given by center_to_topleft', function ()
    text_helper.print_centered("hello\nworld!", 12, 45, colors.blue)

    local s = assert.spy(api.print)
    s.was_called(2)
    s.was_called_with("hello", 3, 40, colors.blue)
    s.was_called_with("world!", 1, 46, colors.blue)
  end)

end)

describe('print_aligned', function ()

  setup(function ()
    stub(api, "print")
    -- exceptionally, do not stub center_to_topleft
    --   and similar helpers, as we want the values
    --   to still be meaningful
  end)

  teardown(function ()
    api.print:revert()
  end)

  after_each(function ()
    api.print:clear()
  end)

  it('should print text centered with horizontal center alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.horizontal_center, colors.blue)

    local s = assert.spy(api.print)
    s.was_called(1)
    s.was_called_with("hello", 13, 45, colors.blue)
  end)

  it('should print text centered with center alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.center, colors.blue)

    local s = assert.spy(api.print)
    s.was_called(1)
    s.was_called_with("hello", 13, 43, colors.blue)
  end)

  it('should print text from the left with left alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.left, colors.blue)

    local s = assert.spy(api.print)
    s.was_called(1)
    s.was_called_with("hello", 22, 45, colors.blue)
  end)

  it('should print text from the right with right alignment', function ()
    text_helper.print_aligned("hello", 22, 45, alignments.right, colors.blue)

    local s = assert.spy(api.print)
    s.was_called(1)
    s.was_called_with("hello", 3, 45, colors.blue)
  end)

end)
