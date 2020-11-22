require("engine/test/bustedhelper")
local overlay = require("engine/ui/overlay")

describe('overlay', function ()

  -- dummy drawable struct for demonstration
  local dummy_drawable = new_struct()

  function dummy_drawable:init(colour)
    self.colour = colour
  end

  function dummy_drawable:draw()
  end

  describe('init', function ()

    it('should init overlay with empty named drawables sequence', function ()
      assert.are_same({}, overlay().named_drawables)
    end)

  end)

  describe('_tostring', function ()

    it('should return "overlay(drawable names: {...})"', function ()
      local overlay_instance = overlay()
      overlay_instance.named_drawables = {{"title", "dummy drawable"}, {"hud", "dummy drawable"}}
      assert.are_equal('overlay(drawable names: {"title", "hud"})', overlay_instance:_tostring())
    end)

  end)

  describe('(overlay instance)', function ()

    local overlay_instance

    before_each(function ()
      overlay_instance = overlay()
    end)

    describe('(no drawables)', function ()

      describe('add_drawable', function ()

        it('should add a new drawable in a table {name, drawable} (drawable added by ref)', function ()
          local mock = dummy_drawable(colors.white)
          overlay_instance:add_drawable("test", mock)
          assert.are_same({{"test", mock}}, overlay_instance.named_drawables)
          assert.are_equal(mock, overlay_instance.named_drawables[1][2])
        end)

      end)

    end)

    describe('(drawable "mock" and "mock2" added)', function ()

      local mock
      local mock2

      before_each(function ()
        mock = dummy_drawable(colors.blue)
        mock2 = dummy_drawable(colors.dark_purple)
        overlay_instance:add_drawable("mock", mock)
        overlay_instance:add_drawable("mock2", mock2)
      end)

      describe('add_drawable', function ()

        it('should replace an existing drawable\'s content while preserving the reference', function ()
          local mock3 = dummy_drawable(colors.yellow)
          overlay_instance:add_drawable("mock", mock3)

          assert.are_same({"mock", mock3}, overlay_instance.named_drawables[1])  -- content is same
          assert.are_not_equal(mock3, overlay_instance.named_drawables[1][2])  -- reference is not same, mock3 was thrown away
          assert.are_equal(mock, overlay_instance.named_drawables[1][2])  -- this proves the mock object reference didn't change
        end)

      end)

      describe('remove_drawable', function ()

        local warn_stub

        setup(function ()
          warn_stub = stub(_G, "warn")
        end)

        teardown(function ()
          warn_stub:revert()
        end)

        after_each(function ()
          warn_stub:clear()
        end)

        it('should remove an existing drawable from the sequence, offset any elements afterward', function ()
          overlay_instance:remove_drawable("mock")
          assert.are_same({{"mock2", mock2}}, overlay_instance.named_drawables)
        end)

        it('should warn if the drawable name is not found', function ()
          overlay_instance:remove_drawable("test")
          assert.spy(warn_stub).was_called(1)
          assert.spy(warn_stub).was_called_with('overlay:remove_drawable: could not find drawable with name: \'test\'', 'ui')
        end)

      end)

      describe('clear_drawables', function ()

        it('should clear any existing drawable', function ()
          overlay_instance:clear_drawables()
          return is_empty(overlay_instance.named_drawables)
        end)

      end)

      describe('draw_drawables', function ()

        setup(function ()
          stub(dummy_drawable, "draw")
        end)

        teardown(function ()
          dummy_drawable.draw:revert()
        end)

        it('should call drawable draw on each drawable', function ()
          overlay_instance:draw()

          assert.spy(dummy_drawable.draw).was_called(2)
          assert.spy(dummy_drawable.draw).was_called_with(match.ref(overlay_instance.named_drawables[1][2]))
          assert.spy(dummy_drawable.draw).was_called_with(match.ref(overlay_instance.named_drawables[2][2]))
        end)

      end)

    end)  -- (drawable "mock" and "mock2" added)

  end)  -- (overlay instance)

end)  -- overlay
