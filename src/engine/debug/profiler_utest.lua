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

    describe('fill_stats', function ()

      it('should initialize the profiler, invisible, with stat labels and correct callbacks', function ()
        local add_label_global_stub = stub(profiler.window, "add_label")

        profiler.window:fill_stats(colors.red)

        local s = assert.spy(add_label_global_stub)
        s.was_called(6)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[1], colors.red, 1, 1)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[2], colors.red, 1, 7)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[3], colors.red, 1, 13)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[4], colors.red, 1, 19)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[5], colors.red, 1, 25)
        s.was_called_with(match.ref(profiler.window), profiler.stat_functions[6], colors.red, 1, 31)
      end)

    end)

  end)

end)
