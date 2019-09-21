require("engine/test/bustedhelper")
local profiler = require("engine/debug/profiler")

describe('profiler', function ()

  setup(function ()
    pico8.memory_usage = 152
  end)

  describe('get_stat_function', function ()

    it('should return a function that returns a stat name padded', function ()
      local mem_stat_function = profiler.get_stat_function(1)
      assert.are_equal("memory     152", mem_stat_function())
    end)

  end)

  describe('window', function ()

    after_each(function ()
      profiler.window:init()
    end)

    describe('init', function ()

      it('should set _initialized_stats to false', function ()
        assert.are_equal(false, profiler.window._initialized_stats)
      end)

    end)

    describe('fill_stats', function ()

      setup(function ()
        stub(profiler.window, "add_label")
      end)

      teardown(function ()
        profiler.window.add_label:revert()
      end)

      after_each(function ()
        profiler.window.add_label:clear()
      end)

      it('should initialize the profiler, invisible, with stat labels and correct callbacks', function ()
        profiler.window:fill_stats(colors.red)

        local s = assert.spy(profiler.window.add_label)
        s.was_called(6)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[1], colors.red, 1, 1)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[2], colors.red, 1, 7)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[3], colors.red, 1, 13)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[4], colors.red, 1, 19)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[5], colors.red, 1, 25)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[6], colors.red, 1, 31)
      end)

      it('should use default color: white if not passed', function ()
        profiler.window:fill_stats()

        local s = assert.spy(profiler.window.add_label)
        s.was_called(6)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[1], colors.white, 1, 1)
        -- no need to test all the other calls, the test above should have been enough
      end)

      it(' should set _initialized_stats to true', function ()
        profiler.window:show()

        assert.are_equal(true, profiler.window._initialized_stats)
      end)

    end)

    describe('show', function ()

      setup(function ()
        stub(profiler.window, "fill_stats")
        stub(debug_window, "show")
      end)

      teardown(function ()
        profiler.window.fill_stats:revert()
        debug_window.show:revert()
      end)

      after_each(function ()
        profiler.window.fill_stats:clear()
        debug_window.show:clear()
      end)

      describe('(not initialized yet)', function ()

        it('should fill stats with passed color', function ()
          profiler.window:show(colors.red)

          local s = assert.spy(profiler.window.fill_stats)
          s.was_called(1)
          s.was_called_with(match.ref(profiler.window), colors.red)
        end)

      end)

      describe('(already initialized)', function ()

        before_each(function ()
          -- fake initialization
          profiler.window._initialized_stats = true
        end)

        it('should not fill stats', function ()
          profiler.window:show()

          local s = assert.spy(profiler.window.fill_stats)
          s.was_not_called()
        end)

      end)

      it('should call base show', function ()
        profiler.window:show()

        local s = assert.spy(debug_window.show)
        s.was_called(1)
        s.was_called_with(match.ref(profiler.window))
      end)

    end)

  end)

end)
