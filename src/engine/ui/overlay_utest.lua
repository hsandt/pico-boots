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
      local overlay_instance = overlay()
      assert.are_same({{}, {}}, {overlay_instance.drawables_seq, overlay_instance.drawables_map})
    end)

  end)

  describe('_tostring', function ()

    it('should return "overlay(drawable names: {...})"', function ()
      local overlay_instance = overlay()
      -- we don't use drawables_seq here
      overlay_instance.drawables_map = {title = "dummy drawable", hud = "dummy drawable"}
      -- alphabetical order as busted has access to #dump
      assert.are_equal('overlay(drawable names: {"hud", "title"})', overlay_instance:_tostring())
    end)

  end)

  describe('(overlay instance)', function ()

    local overlay_instance

    before_each(function ()
      overlay_instance = overlay()
    end)

    describe('(no drawables)', function ()

      describe('add_drawable', function ()

        it('should add a new drawable in a sequence with named reference in map', function ()
          local mock = dummy_drawable(colors.white)
          overlay_instance:add_drawable("mock", mock)

          assert.are_same({mock}, overlay_instance.drawables_seq)
          assert.is_true(rawequal(mock, overlay_instance.drawables_seq[1]))

          assert.are_same({mock = mock}, overlay_instance.drawables_map)
          assert.is_true(rawequal(mock, overlay_instance.drawables_map["mock"]))
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

          assert.are_same({mock3, mock2}, overlay_instance.drawables_seq)    -- content has been set
          assert.are_not_equal(mock3, overlay_instance.drawables_seq[1])     -- reference is not same, mock3 was thrown away
          assert.is_true(rawequal(mock, overlay_instance.drawables_seq[1]))  -- this proves the mock object reference didn't change

          assert.are_same({mock = mock3, mock2 = mock2}, overlay_instance.drawables_map)
          assert.are_not_equal(mock3, overlay_instance.drawables_map["mock"])
          assert.is_true(rawequal(mock, overlay_instance.drawables_map["mock"]))
        end)

      end)

      describe('remove_drawable', function ()

        local warn_stub

        setup(function ()
          stub(_G, "warn")
        end)

        teardown(function ()
          warn:revert()
        end)

        after_each(function ()
          warn:clear()
        end)

        it('should remove an existing drawable from the sequence, offset any elements afterward', function ()
          overlay_instance:remove_drawable("mock")
          assert.are_same({mock2}, overlay_instance.drawables_seq)
          assert.are_same({mock2 = mock2}, overlay_instance.drawables_map)
        end)

        it('should warn if the drawable name is not found', function ()
          overlay_instance:remove_drawable("unknown")
          assert.spy(warn).was_called(1)
          assert.spy(warn).was_called_with('overlay:remove_drawable: could not find drawable with name: \'unknown\'', 'ui')
        end)

      end)

      describe('clear_drawables', function ()

        it('should clear any existing drawable', function ()
          overlay_instance:clear_drawables()
          assert.are_same({}, overlay_instance.drawables_seq)
          assert.are_same({}, overlay_instance.drawables_map)
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
          assert.spy(dummy_drawable.draw).was_called_with(match.ref(overlay_instance.drawables_seq[1]))
          assert.spy(dummy_drawable.draw).was_called_with(match.ref(overlay_instance.drawables_seq[2]))
        end)

      end)

    end)  -- (drawable "mock" and "mock2" added)

  end)  -- (overlay instance)

end)  -- overlay
