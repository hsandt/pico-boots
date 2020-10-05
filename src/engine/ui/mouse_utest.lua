require("engine/test/bustedhelper")
local mouse = require("engine/ui/mouse")

local input = require("engine/input/input")
local sprite_data = require("engine/render/sprite_data")

describe('mouse', function ()

  describe('render', function ()

    describe('(without cursor sprite data)', function ()

      describe('(mouse off)', function ()

        it('should not error (by testing for nil)', function ()
          assert.has_no_errors(function () mouse:render() end)
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
          assert.has_no_errors(function () mouse:render() end)
        end)

      end)

    end)  -- (without cursor sprite data)

    describe('(with cursor sprite data)', function ()

      local cursor_render_stub

      setup(function ()
        mouse:set_cursor_sprite_data(sprite_data(sprite_id_location(1, 0)))
        cursor_render_stub = stub(mouse.cursor_sprite_data, "render")
      end)

      teardown(function ()
        cursor_render_stub:revert()
      end)

      after_each(function ()
        cursor_render_stub:clear()
      end)

      describe('(mouse off)', function ()

        it('should not call cursor sprite render', function ()
          mouse:render()
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
          mouse:render()
          assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
          assert.spy(cursor_render_stub).was_called(1)
          assert.spy(cursor_render_stub).was_called_with(match.ref(mouse.cursor_sprite_data), vector(12, 48))
        end)

      end)

    end)  -- (with cursor sprite data)

  end)  -- mouse.render

end)
