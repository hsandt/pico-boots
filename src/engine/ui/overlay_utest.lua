require("engine/test/bustedhelper")
local overlay = require("engine/ui/overlay")
local label = require("engine/ui/label")

describe('overlay', function ()

  describe('init', function ()

    it('should init overlay with empty labels sequence', function ()
      assert.are_same({}, overlay().labels)
    end)

  end)

  describe('_tostring', function ()

    it('should return "overlay(X label(s))"', function ()
      local overlay_instance = overlay()
      overlay_instance.labels = {1, 2, 3}
      assert.are_equal("overlay(3 label(s))", overlay_instance:_tostring())
    end)

  end)

  describe('(overlay instance)', function ()

    local overlay_instance

    setup(function ()
      overlay_instance = overlay()
    end)

    describe('(no labels)', function ()

      teardown(function ()
        clear_table(overlay_instance.labels)
      end)

      describe('add_label', function ()

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

        it('should add a new label', function ()
          overlay_instance:add_label("test", "content", vector(2, 4), colors.red)
          assert.are_same(label("content", vector(2, 4), colors.red), overlay_instance.labels["test"])
        end)

        it('should add a new black label with warning if no colour is passed', function ()
          overlay_instance:add_label("test", "content", vector(2, 4))
          assert.spy(warn_stub).was_called(1)
          assert.spy(warn_stub).was_called_with('overlay:add_label no colour passed, will default to black (0)', 'ui')
          assert.are_same(label("content", vector(2, 4), colors.black), overlay_instance.labels["test"])
        end)

      end)

    end)

    describe('(label "mock" and "mock2" added)', function ()

      before_each(function ()
        overlay_instance:add_label("mock", "mock content", vector(1, 1), colors.blue)
        overlay_instance:add_label("mock2", "mock content 2", vector(2, 2), colors.dark_purple)
      end)

      after_each(function ()
        clear_table(overlay_instance.labels)
      end)

      describe('add_label', function ()

        it('should replace an existing label', function ()
          overlay_instance:add_label("mock", "mock content 2", vector(3, 7), colors.white)
          assert.are_same(label("mock content 2", vector(3, 7), colors.white), overlay_instance.labels["mock"])
        end)

      end)

      describe('remove_label', function ()

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

        it('should remove an existing label', function ()
          overlay_instance:remove_label("mock")
          assert.is_nil(overlay_instance.labels["mock"])
        end)

        it('should warn if the label name is not found', function ()
          overlay_instance:remove_label("test")
          assert.spy(warn_stub).was_called(1)
          assert.spy(warn_stub).was_called_with('overlay:remove_label: could not find label with name: \'test\'', 'ui')
          assert.is_nil(overlay_instance.labels["test"])
        end)

      end)

      describe('clear_labels', function ()

        it('should clear any existing label', function ()
          overlay_instance:clear_labels()
          return is_empty(overlay_instance.labels)
        end)

      end)

      describe('draw_labels', function ()

        setup(function ()
          stub(label, "draw")
        end)

        teardown(function ()
          label.draw:revert()
        end)

        it('should call label draw on each label', function ()
          overlay_instance:draw_labels()

          local s = assert.spy(label.draw)
          s.was_called(2)
          s.was_called_with(match.ref(overlay_instance.labels["mock"]))
          s.was_called_with(match.ref(overlay_instance.labels["mock2"]))
        end)

      end)

    end)  -- (label "mock" and "mock2" added)

  end)  -- (overlay instance)

end)  -- overlay
