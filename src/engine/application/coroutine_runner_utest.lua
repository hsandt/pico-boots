require("engine/test/bustedhelper")
local coroutine_runner = require("engine/application/coroutine_runner")

describe('coroutine_runner', function ()

  local runner

  before_each(function ()
    runner = coroutine_runner()
  end)

  describe('_init', function ()
    it('should init empty coroutine curry sequence', function ()
      assert.are_same({}, runner.coroutine_curries)
    end)
  end)

  describe('working coroutine function', function ()

    local test_var = 0

    local function set_var_after_delay_async(nb_frames, value)
      yield_delay(nb_frames)
      test_var = value
    end

    describe('start_coroutine', function ()

      it('should start a coroutine, stopping at the first yield', function ()
        runner:start_coroutine(set_var_after_delay_async)

        -- we cannot easily check a thread content so it's hard to verify that make_safe
        --   was applied, and that the result was passed to cocreate, unless we stub both functions
        -- so we just test generic values
        assert.are_equal(1, #runner.coroutine_curries)
        assert.are_equal("suspended", costatus(runner.coroutine_curries[1].coroutine))
        assert.are_equal(0, test_var)
      end)

    end)

    describe('(2 coroutines started with yield_delays of 30 and 60 frames resp.)', function ()

      before_each(function ()
        test_var = 0
        runner:start_coroutine(set_var_after_delay_async, 30, 1)
        runner:start_coroutine(set_var_after_delay_async, 60, 2)
      end)

      after_each(function ()
        clear_table(runner.coroutine_curries)
      end)

      describe('update_coroutines', function ()

        it('should update all the coroutines (not enough time to finish any coroutine)', function ()
          for t = 1, 29 do
            runner:update_coroutines()
          end
          assert.are_equal(2, #runner.coroutine_curries)
          assert.are_same({"suspended", "suspended"}, {costatus(runner.coroutine_curries[1].coroutine), costatus(runner.coroutine_curries[2].coroutine)})
          assert.are_equal(0, test_var)
        end)

        it('should update all the coroutines (just enough time to finish the first one but not the second one)', function ()
          for t = 1, 30 do
            runner:update_coroutines()
          end
          assert.are_equal(2, #runner.coroutine_curries)
          assert.are_same({"dead", "suspended"}, {costatus(runner.coroutine_curries[1].coroutine), costatus(runner.coroutine_curries[2].coroutine)})
          assert.are_equal(1, test_var)
        end)

        it('should remove dead coroutines on the next call after finish (remove first one when dead)', function ()
          for t = 1, 31 do
            runner:update_coroutines()
          end
          -- 1st coroutine has been removed, so the only coroutine left at index 1 is now the 2nd coroutine
          assert.are_equal(1, #runner.coroutine_curries)
          assert.are_equal("suspended", costatus(runner.coroutine_curries[1].coroutine))
          assert.are_equal(1, test_var)
        end)

        it('should update all the coroutines (just enough time to finish the second one)', function ()
          for t = 1, 60 do
            runner:update_coroutines()
          end
          assert.are_equal(1, #runner.coroutine_curries)
          assert.are_equal("dead", costatus(runner.coroutine_curries[1].coroutine))
          assert.are_equal(2, test_var)
        end)

        it('should remove dead coroutines on the next call after finish (remove second one when dead)', function ()
          for t = 1, 61 do
            runner:update_coroutines()
          end
          assert.are_equal(0, #runner.coroutine_curries)
          assert.are_equal(2, test_var)
        end)

      end)  -- update_coroutines

      describe('stop_all_coroutines', function ()

        it('should clear the sequence of coroutine curries', function ()
          runner:stop_all_coroutines()

          assert.are_equal(0, #runner.coroutine_curries)
        end)

      end)  -- stop_all_coroutines

    end)  -- (2 coroutines started with yield_delays of 30 and 60 frames resp.)

  end)  -- working coroutine function

  describe('coroutine updating coroutines', function ()

    local test_var = 0
    local warn_stub

    local function update_coroutine_recursively_async()
      test_var = test_var + 1
      runner:update_coroutines()
    end

    setup(function ()
      warn_stub = stub(_G, "warn")
    end)

    teardown(function ()
      warn_stub:revert()
    end)

    before_each(function ()
      runner:start_coroutine(update_coroutine_recursively_async)
    end)

    after_each(function ()
      warn_stub:clear()
    end)

    it('should resume the coroutine on 1 level only and warn that you shouldn\'t update resume already running coroutines', function ()
      runner:update_coroutines()
      assert.are_equal(1, test_var)  -- proves we entered the coroutine function only once
      assert.spy(warn_stub).was_called(1)
      assert.spy(warn_stub).was_called_with(match.matches("coroutine_runner:update_coroutines: coroutine should not be running outside its body: "), "flow")
    end)

  end)

  describe('(failing coroutine started)', function ()

    local function fail_async(nb_frames)
      yield_delay(nb_frames)
      error("fail_async failed forcefully")  -- line 156 -> update test string if you move this
    end

    before_each(function ()
      runner:start_coroutine(fail_async, 30)
    end)

    after_each(function ()
      clear_table(runner.coroutine_curries)
    end)

    describe('update_coroutines', function ()

      setup(function ()
        stub(_G, "err")
      end)

      teardown(function ()
        err:revert()
      end)

      after_each(function ()
        err:clear()
      end)

      it('should not assert when an error doesn\'t occurs inside the coroutine resume yet', function ()
        assert.has_no_errors(function () runner:update_coroutines() end)
      end)

      it('should assert when an error occurs inside the coroutine resume on frame 30, showing the error message', function ()
        for t = 1, 29 do
          runner:update_coroutines()
        end

        -- this test actually also verifies that make_safe is working correctly
        assert.has_error(function ()
            runner:update_coroutines()
          end)
          -- exact path and line are a bit too unstable, but error message should be like this:
          -- "coroutine update failed (now dead) with:\n./src/engine/application/coroutine_runner_utest.lua:156: fail_async failed forcefully"
          -- but sometimes it starts with "...-boots/src"
      end)

    end)

  end)  -- (failing coroutine started)

  describe('(coroutine method for custom class started with yield_delay of 30)', function ()

    local test_class = new_class()
    local test_instance

    function test_class:_init(value)
      self.value = value
    end

    function test_class:set_value_after_delay(new_value)
      yield_delay(30)
      self.value = new_value
    end

    before_each(function ()
      -- create an instance and pass it to start_coroutine as the future self arg,
      --   so the method can work properly
      test_instance = test_class(-10)
      runner:start_coroutine(test_class.set_value_after_delay, test_instance, 99)
    end)

    after_each(function ()
      clear_table(runner.coroutine_curries)
    end)

    describe('update_coroutines', function ()

      it('should update all the coroutines (not enough time to finish any coroutine)', function ()
        for t = 1, 29 do
          runner:update_coroutines()
        end
        assert.are_equal(1, #runner.coroutine_curries)
        assert.are_equal("suspended", costatus(runner.coroutine_curries[1].coroutine))
        assert.are_equal(-10, test_instance.value)
      end)

      it('should update all the coroutines (just enough time to finish)', function ()
        for t = 1, 30 do
          runner:update_coroutines()
        end
        assert.are_equal(1, #runner.coroutine_curries)
        assert.are_equal("dead", costatus(runner.coroutine_curries[1].coroutine))
        assert.are_equal(99, test_instance.value)
      end)

      it('should remove dead coroutines on the next call after finish after finish', function ()
        for t = 1, 31 do
          runner:update_coroutines()
        end
        assert.are_equal(0, #runner.coroutine_curries)
        assert.are_equal(99, test_instance.value)
      end)

    end)

  end)

  describe('make_safe', function ()

    local function no_error()
    end

    local function fail_immediate_async()
      error("fail_immediate_async failed forcefully")  -- line 265 -> update test string if you move this
    end

    it('should decorate a function that if already safe, acts as usual', function ()
      local safe_no_error = runner:make_safe(no_error)
      assert.has_no_errors(function ()
          safe_no_error()
        end)
      assert.is_nil(runner.last_error)
    end)

    it('should decorate a function so any error will set last_error and still cause an error', function ()
      local safe_fail_immediate_async = runner:make_safe(fail_immediate_async)

      --[[
      The exact error message should be something like:

      './src/engine/application/coroutine_runner_utest.lua:266: fail_immediate_async failed forcefully
      stack traceback:
        ...

      which is too complicated to test, so we just test the presence of an error.

      Real case uage will show you if the error message is good enough.
      --]]
      assert.has_error(function ()
          safe_fail_immediate_async()
        end)

      -- exact path and line are a bit too unstable, but error message should be like this:
      -- assert.are_equal("./src/engine/application/coroutine_runner_utest.lua:265: fail_immediate_async failed forcefully", runner.last_error)
      -- but sometimes it starts with "...-boots/src"
    end)

  end)

end)  -- coroutine_runner
