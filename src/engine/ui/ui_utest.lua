require("engine/test/bustedhelper")
local ui = require("engine/ui/ui")

local input = require("engine/input/input")
local sprite_data = require("engine/render/sprite_data")

describe('ui', function ()

  describe('render_mouse', function ()

    describe('(without cursor sprite data)', function ()

      describe('(mouse off)', function ()

        it('should not error (by testing for nil)', function ()
          assert.has_no_errors(function () ui:render_mouse() end)
        end)

      end)

      describe('(mouse on at (12, 48))', function ()

        setup(function ()
          input:toggle_mouse(true)
          pico8.mousepos.x = 12
          pico8.mousepos.y = 48
        end)

        teardown(function ()
          input:toggle_mouse(false)
        end)

        it('should not error (by testing for nil)', function ()
          assert.has_no_errors(function () ui:render_mouse() end)
        end)

      end)

    end)  -- (without cursor sprite data)

    describe('(with cursor sprite data)', function ()

      local cursor_render_stub

      setup(function ()
        ui:set_cursor_sprite_data(sprite_data(sprite_id_location(1, 0)))
        cursor_render_stub = stub(ui.cursor_sprite_data, "render")
      end)

      teardown(function ()
        cursor_render_stub:revert()
      end)

      after_each(function ()
        cursor_render_stub:clear()
      end)

      describe('(mouse off)', function ()

        it('should not call cursor sprite render', function ()
          ui:render_mouse()
          assert.spy(cursor_render_stub).was_not_called()
        end)

      end)

      describe('(mouse shown at (12, 48))', function ()

        setup(function ()
          input:toggle_mouse(true)
          pico8.mousepos.x = 12
          pico8.mousepos.y = 48
        end)

        teardown(function ()
          input:toggle_mouse(false)
        end)

        -- bugfix history:
        -- .. i forgot to use match.ref, which was ok until struct_eq uses are_same with compare_raw_content: true
        --    which causes infinite recursion when trying to compare a spied method on a struct (as it contains a ref to itself)
        it('should call cursor sprite render at (12, 48)', function ()
          ui:render_mouse()
          assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
          assert.spy(cursor_render_stub).was_called(1)
          assert.spy(cursor_render_stub).was_called_with(match.ref(ui.cursor_sprite_data), vector(12, 48))
        end)

      end)

    end)  -- (with cursor sprite data)

  end)  -- ui.render_mouse

  describe('center_x_to_left', function ()

    it('should return the position minus the text half-width + offset 1', function ()
      assert.are_equal(3, ui.center_x_to_left("hello", 12))
    end)

  end)

  describe('center_y_to_top', function ()

    it('should return the position minus the text half-height + offset 1', function ()
      assert.are_equal(43, ui.center_y_to_top("hello", 45))
    end)

  end)

  describe('center_to_topleft', function ()

    it('should return the position minus the text half-size + offset (1, 1)', function ()
      assert.are_same({3, 43}, {ui.center_to_topleft("hello", 12, 45)})
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

    -- we didn't stub ui.print_centered, so we rely on print_centered being correct

    it('should print single-line text at position given by center_to_topleft', function ()
      ui.print_centered("hello", 12, 45, colors.blue)

      local s = assert.spy(api.print)
      s.was_called(1)
      s.was_called_with("hello", 3, 43, colors.blue)
    end)

    it('should print multi-line text line by line at positions given by center_to_topleft', function ()
      ui.print_centered("hello\nworld!", 12, 45, colors.blue)

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
      ui.print_aligned("hello", 22, 45, alignments.horizontal_center, colors.blue)

      local s = assert.spy(api.print)
      s.was_called(1)
      s.was_called_with("hello", 13, 45, colors.blue)
    end)

    it('should print text centered with center alignment', function ()
      ui.print_aligned("hello", 22, 45, alignments.center, colors.blue)

      local s = assert.spy(api.print)
      s.was_called(1)
      s.was_called_with("hello", 13, 43, colors.blue)
    end)

    it('should print text from the left with left alignment', function ()
      ui.print_aligned("hello", 22, 45, alignments.left, colors.blue)

      local s = assert.spy(api.print)
      s.was_called(1)
      s.was_called_with("hello", 22, 45, colors.blue)
    end)

    it('should print text from the right with right alignment', function ()
      ui.print_aligned("hello", 22, 45, alignments.right, colors.blue)

      local s = assert.spy(api.print)
      s.was_called(1)
      s.was_called_with("hello", 3, 45, colors.blue)
    end)

  end)

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
      ui.draw_box(10, 20, 40, 50, colors.black, colors.blue)

      local s = assert.spy(rect)
      s.was_called(1)
      s.was_called_with(10, 20, 40, 50, colors.black)
    end)

    it('should fill a rect with padding 1px for the background', function ()
      ui.draw_box(10, 20, 40, 50, colors.black, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(1)
      s.was_called_with(11, 21, 39, 49, colors.blue)
    end)

    it('should fill a rect with padding 1px, supporting bottom and right coord first', function ()
      ui.draw_box(40, 50, 10, 20, colors.black, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(1)
      s.was_called_with(11, 21, 39, 49, colors.blue)
    end)

    it('should not fill a rect with padding 1px if box is too small', function ()
      ui.draw_box(10, 20, 40, 21, colors.black, colors.blue)

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
      ui.draw_rounded_box(10, 20, 40, 50, colors.black, colors.blue)

      local s = assert.spy(line)
      s.was_called(4)
      s.was_called_with(11, 20, 39, 20, colors.black)
      s.was_called_with(40, 21, 40, 49, colors.black)
      s.was_called_with(39, 50, 11, 50, colors.black)
      s.was_called_with(10, 49, 10, 21, colors.black)
    end)

    it('should fill a rect with padding 1px for the background', function ()
      ui.draw_rounded_box(10, 20, 40, 50, colors.black, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(1)
      s.was_called_with(11, 21, 39, 49, colors.blue)
    end)

    it('should fill a rect with padding 1px, supporting bottom and right coord first', function ()
      ui.draw_rounded_box(40, 50, 10, 20, colors.black, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(1)
      s.was_called_with(11, 21, 39, 49, colors.blue)
    end)

    it('should not fill a rect with padding 1px if box is too small', function ()
      ui.draw_rounded_box(10, 20, 40, 21, colors.black, colors.blue)

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
      ui.draw_gauge(10, 20, 40, 50, 0, directions.right, colors.black, colors.white, colors.blue)

      local s = assert.spy(rect)
      s.was_called(1)
      s.was_called_with(10, 20, 40, 50, colors.black)
    end)

    it('should fill a rect with padding 1px for the background, but no extra fill if gauge is too small', function ()
      ui.draw_gauge(10, 20, 40, 50, 0, directions.right, colors.black, colors.white, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(1)
      s.was_called_with(11, 21, 39, 49, colors.white)
    end)

    it('should fill a rect with padding 1px, supporting bottom and right coord first, but no extra fill if gauge is too small', function ()
      ui.draw_gauge(40, 50, 10, 20, 0, directions.right, colors.black, colors.white, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(1)
      s.was_called_with(11, 21, 39, 49, colors.white)
    end)

    it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward right)', function ()
      ui.draw_gauge(10, 20, 41, 51, 0.5, directions.left, colors.black, colors.white, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(2)
      s.was_called_with(11, 21, 40, 50, colors.white)
      s.was_called_with(26, 21, 40, 50, colors.blue)
    end)

    it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward right)', function ()
      ui.draw_gauge(10, 20, 41, 51, 0.5, directions.right, colors.black, colors.white, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(2)
      s.was_called_with(11, 21, 40, 50, colors.white)
      s.was_called_with(11, 21, 25, 50, colors.blue)
    end)

    it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward down and inverted coords)', function ()
      ui.draw_gauge(61, 71, 50, 20, 0.5, directions.down, colors.black, colors.white, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(2)
      s.was_called_with(51, 21, 60, 70, colors.white)
      s.was_called_with(51, 21, 60, 45, colors.blue)
    end)

    it('should fill a rect with padding 1px for the background, and extra fill matching fill ratio (toward up and inverted coords)', function ()
      ui.draw_gauge(61, 71, 50, 20, 0.5, directions.up, colors.black, colors.white, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(2)
      s.was_called_with(51, 21, 60, 70, colors.white)
      s.was_called_with(51, 46, 60, 70, colors.blue)
    end)

    it('should fill a rect with padding 1px for the background, and full fill (toward down and inverted coords)', function ()
      ui.draw_gauge(61, 71, 50, 20, 1, directions.down, colors.black, colors.white, colors.blue)

      local s = assert.spy(rectfill)
      s.was_called(2)
      s.was_called_with(51, 21, 60, 70, colors.white)
      s.was_called_with(51, 21, 60, 70, colors.blue)
    end)

    it('should not rectfill at all if box is too small', function ()
      ui.draw_gauge(10, 20, 40, 21, 0, directions.right, colors.black, colors.white, colors.blue)

      assert.spy(rectfill).was_not_called()
    end)

  end)

end)
