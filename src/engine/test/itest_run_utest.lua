require("engine/test/bustedhelper")
local itest_run = require("engine/test/itest_run")
local test_states = itest_run.test_states

local gameapp = require("engine/application/gameapp")
local logging = require("engine/debug/logging")
local input = require("engine/input/input")
local integration_test = require("engine/test/integration_test")
local itest_manager = require("engine/test/itest_manager")
local time_trigger = require("engine/test/time_trigger")

local function repeat_callback(time, callback)
  -- ceil is just for times with precision of 0.01 or deeper,
  -- so the last frame is reached (e.g. an action at t=0.01 is applied)
  -- caution: this may make fractional times advance too much and apply actions they shouldn't,

  -- works with time_triggers using fps = 60
  for i = 1, ceil(time * 60) do
   callback()
  end
end

describe('itest_run', function ()

  -- prepare mock app with default implementation
  local mock_app = gameapp(60)

  local test
  local instance

  before_each(function ()
    test = integration_test('character walks', {':stage'})
    -- simpler to pass real itest manager and reset it in after_each
    --  than create a mockup
    instance = itest_run(itest_manager)
  end)

  after_each(function ()
    -- full reset
    input.mode = input_modes.native
    itest_manager:init()
  end)

  describe('init', function ()

    it('should initialize parameters', function ()
      assert.are_same({
          false,
          nil,
          0,
          0,
          1,
          test_states.none,
          nil,
          nil
        },
        {
          instance.initialized,
          instance.current_test,
          instance.current_frame,
          instance.last_trigger_frame,
          instance.next_action_index,
          instance.current_state,
          instance.current_message,
          instance.gameapp
        })
    end)

  end)

  describe('init_game_and_start', function ()

    setup(function ()
      stub(gameapp, "start")
      stub(itest_run, "stop_and_reset_game")
      stub(itest_run, "start")
    end)

    teardown(function ()
      gameapp.start:revert()
      itest_run.stop_and_reset_game:revert()
      itest_run.start:revert()
    end)

    after_each(function ()
      gameapp.start:clear()
      itest_run.stop_and_reset_game:clear()
      itest_run.start:clear()
    end)

    it('should error if app is not set', function ()

      assert.has_error(function ()
        instance:init_game_and_start(test)
      end, "itest_run:init_game_and_start: self.app is not set")
    end)

    describe('(with mock app)', function ()

      before_each(function ()
        instance.app = mock_app
      end)

      describe('(when current_test is already set)', function ()

        before_each(function ()
          instance.current_test = test
        end)

        it('should error', function ()
          assert.has_error(function ()
            instance:init_game_and_start(test)
          end, "itest_run:init_game_and_start: test is still running")
        end)

      end)

      it('should start the gameapp', function ()
        instance:init_game_and_start(test)

        local s = assert.spy(gameapp.start)
        s.was_called(1)
        s.was_called_with(match.ref(mock_app))
      end)

      it('should init a set gameapp and the passed test', function ()
        instance:init_game_and_start(test)

        assert.spy(itest_run.start).was_called(1)
        assert.spy(itest_run.start).was_called_with(match.ref(instance), test)
      end)

    end)

  end)

  describe('stop_and_reset_game', function ()

    setup(function ()
      stub(gameapp, "reset")
      stub(itest_run, "stop")
    end)

    teardown(function ()
      gameapp.reset:revert()
      itest_run.stop:revert()
    end)

    after_each(function ()
      gameapp.reset:clear()
      itest_run.stop:clear()
    end)

    it('should error if app is not set', function ()

      assert.has_error(function ()
        instance:stop_and_reset_game(test)
      end, "itest_run:stop_and_reset_game: self.app is not set")
    end)

    describe('(with mock app)', function ()

      before_each(function ()
        instance.app = mock_app
      end)

      describe('(when current_test is already set)', function ()

        before_each(function ()
          instance.current_test = test
        end)

        it('should reset the app', function ()
          instance:stop_and_reset_game(test)

          assert.spy(gameapp.reset).was_called(1)
          assert.spy(gameapp.reset).was_called_with(match.ref(mock_app))
        end)

        it('should stop', function ()
          instance:stop_and_reset_game(test)

          assert.spy(itest_run.stop).was_called(1)
          assert.spy(itest_run.stop).was_called_with(match.ref(instance))
        end)

      end)

    end)

  end)

  describe('(with mock app)', function ()

    before_each(function ()
      instance.app = mock_app
    end)

    describe('update_game_and_test', function ()

      setup(function ()
        stub(itest_run, "step_game_and_test")
      end)

      teardown(function ()
        itest_run.step_game_and_test:revert()
      end)

      after_each(function ()
        itest_run.step_game_and_test:clear()
      end)

      describe('(when state is not running)', function ()

        it('should do nothing', function ()
          instance:update_game_and_test()

          assert.spy(itest_run.step_game_and_test).was_not_called()
        end)

      end)

      describe('(when state is running)', function ()

        it('should call step_game_and_test', function ()
          instance.current_state = test_states.running

          instance:update_game_and_test()

          assert.spy(itest_run.step_game_and_test).was_called(1)
          assert.spy(itest_run.step_game_and_test).was_called_with(match.ref(instance))
        end)

      end)

    end)

    describe('step_game_and_test', function ()

      setup(function ()
        stub(gameapp, "update")
        spy.on(itest_run, "update")
      end)

      teardown(function ()
        gameapp.update:revert()
        itest_run.update:revert()
      end)

      after_each(function ()
        gameapp.update:clear()
        itest_run.update:clear()
      end)

      describe('(when state is running for some actions)', function ()

        before_each(function ()
          test:add_action(time_trigger(1.0, false, 60), function () end, 'some_action')
        end)

        it('should update the set gameapp and the passed test', function ()
          instance:start(test)

          instance:step_game_and_test()

          assert.spy(gameapp.update).was_called(1)
          assert.spy(gameapp.update).was_called_with(match.ref(mock_app))
          assert.spy(itest_run.update).was_called(1)
          assert.spy(itest_run.update).was_called_with(match.ref(instance))
        end)

      end)

      describe('(when running, and test ends on this update with success)', function ()

        before_each(function ()
          test:add_action(time_trigger(0.017, false, 60), function () end, 'some_action')
          instance:start(test)
        end)

        setup(function ()
          stub(_G, "log")
        end)

        teardown(function ()
          log:revert()
        end)

        after_each(function ()
          log:clear()
        end)

        it('should only log the result', function ()
          instance:step_game_and_test()
          local s = assert.spy(log)
          s.was_called()  -- we only want 1 call, but we check "at least once" because there are other unrelated logs
          s.was_called_with("itest 'character walks' ended with success\n", 'itest')
        end)

      end)

      describe('(when running, and test ends on this update with failure)', function ()

        before_each(function ()
          test:add_action(time_trigger(0.017, false, 60), function () end, 'some_action')
          test.final_assertion = function (app)
            return false, "character walks failed"
          end
            instance:start(test)
        end)

        setup(function ()
          stub(_G, "log")
        end)

        teardown(function ()
          log:revert()
        end)

        after_each(function ()
          log:clear()
        end)

        it('should log the result and failure message', function ()
          instance:step_game_and_test()
          local s = assert.spy(log)
          s.was_called()  -- we only want 2 calls, but we check "at least twice" because there are other unrelated logs
          s.was_called_with("itest 'character walks' ended with failure\n", 'itest')
          s.was_called_with("failed: character walks failed\n", 'itest')
        end)

      end)

    end)

    describe('toggle_pause', function ()

      it('should paused the itest if running', function ()
        instance.current_state = test_states.running

        instance:toggle_pause()

        assert.are_equal(test_states.paused, instance.current_state)
      end)

      it('should resume the itest if paused', function ()
        instance.current_state = test_states.paused

        instance:toggle_pause()

        assert.are_equal(test_states.running, instance.current_state)
      end)

    end)

    describe('draw_game', function ()

      setup(function ()
        stub(gameapp, "draw")
      end)

      teardown(function ()
        gameapp.draw:revert()
      end)

      after_each(function ()
        gameapp.draw:clear()
      end)

      it('should draw the gameapp', function ()
        instance:draw_game()

        assert.spy(gameapp.draw).was_called(1)
        assert.spy(gameapp.draw).was_called_with(match.ref(mock_app))
      end)

    end)

    describe('start', function ()

      setup(function ()
        spy.on(itest_run, "initialize")
        spy.on(itest_run, "check_end")
        spy.on(itest_run, "check_next_action")
      end)

      teardown(function ()
        itest_run.initialize:revert()
        itest_run.check_end:revert()
        itest_run.check_next_action:revert()
      end)

      before_each(function ()
        test.setup = spy.new(function () end)
      end)

      after_each(function ()
        itest_run.initialize:clear()
        itest_run.check_end:clear()
        itest_run.check_next_action:clear()
      end)

      it('should set the input mode to simulated', function ()
        instance:start(test)
        assert.are_equal(input_modes.simulated, input.mode)
      end)

      it('should set the current test to the passed test', function ()
        instance:start(test)
        assert.are_equal(test, instance.current_test)
      end)

      it('should initialize state vars', function ()
        instance:start(test)
        assert.are_same({0, 0, 1}, {
          instance.current_frame,
          instance.last_trigger_frame,
          instance.next_action_index
        })
      end)

      it('should call the test setup callback', function ()
        instance:start(test)
        assert.spy(test.setup).was_called(1)
        assert.spy(test.setup).was_called_with(mock_app)
      end)

      it('should call initialize the first time', function ()
        instance:start(test)
        assert.spy(itest_run.initialize).was_called(1)
        assert.spy(itest_run.initialize).was_called_with(match.ref(instance))
      end)

      it('should call check_end', function ()
        instance:start(test)
        assert.spy(itest_run.check_end).was_called(1)
        assert.spy(itest_run.check_end).was_called_with(match.ref(instance))
      end)

      describe('(when no actions)', function ()

        it('should not check the next action', function ()
          instance:start(test)
          assert.spy(itest_run.check_next_action).was_not_called()
        end)

        it('should immediately end the run (result depends on final assertion)', function ()
          instance:start(test)
          assert.are_not_equal(test_states.running, instance.current_state)
        end)

      end)

      describe('(when some actions)', function ()

        before_each(function ()
          test:add_action(time_trigger(1.0, false, 60), function () end, 'some_action')
        end)

        it('should check the next action immediately (if at time 0, will also call it)', function ()
          instance:start(test)
          assert.spy(itest_run.check_next_action).was_called(1)
          assert.spy(itest_run.check_next_action).was_called_with(match.ref(instance))
        end)

        it('should enter running state', function ()
          instance:start(test)
          assert.are_equal(test_states.running, instance.current_state)
        end)

      end)

      describe('(after a first start)', function ()

        before_each(function ()
          test:add_action(time_trigger(1.0, false, 60), function () end, 'restart_action')
          -- some progress
          instance:start(test)
          repeat_callback(1.0, function ()
            instance:update()
          end)
        end)

        it('should not call initialize the second time', function ()
          -- in this specific case, start was called in before_each so we need to clear manually
          -- just before we call start ourselves to have the correct count
          itest_run.initialize:clear()
          instance:start(test)
          assert.spy(itest_run.initialize).was_not_called()
        end)

      end)

    end)

    describe('end_with_final_assertion', function ()

      before_each(function ()
        -- inline some parts of instance:start(test)
        --  to get a boilerplate to test on
        -- avoid calling start() directly as it would call check_end, messing the teardown spy count
        instance:initialize()
        instance.current_test = test
        instance.current_state = test_states.running
      end)

      describe('(when no final assertion)', function ()

        it('should end with success', function ()
          instance:end_with_final_assertion(test)
          assert.are_equal(test_states.success, instance.current_state)
        end)

      end)

      describe('(when final assertion passes)', function ()

        before_each(function ()
          test.final_assertion = function (app)
            assert(app)
            return true
          end
        end)

        it('should check the final assertion and end with success', function ()
          instance:end_with_final_assertion(test)
          assert.are_equal(test_states.success, instance.current_state)
        end)

      end)

      describe('(when final assertion passes)', function ()

        before_each(function ()
          test.final_assertion = function (app)
            return false, "error message"
          end
        end)

        it('should check the final assertion and end with failure', function ()
          instance:end_with_final_assertion(test)
          assert.are_same({test_states.failure, "error message"},
            {instance.current_state, instance.current_message})
        end)

      end)

    end)

  end)  -- (with mock app)

  describe('update', function ()

    it('should assert when no test has been started', function ()
      assert.has_error(function()
        instance:update()
      end,
      "itest_run:update: current_test is not set")
    end)

    describe('(after test started)', function ()

      local action_callback = spy.new(function () end)

      before_each(function ()
        -- need at least 1/60=0.1666s above 1.0s so it's not called after 1.0s converted to frames
        test:add_action(time_trigger(1.02, false, 60), action_callback, 'update_test_action')
      end)

      teardown(function ()
        action_callback:revert()
      end)

      before_each(function ()
        instance:start(test)
      end)

      after_each(function ()
        action_callback:clear()
      end)

      it('should advance the current time by 1', function ()
        instance:update()
        assert.are_equal(1, instance.current_frame)
      end)

      it('should call an initial action (t=0) immediately, preserving last trigger time to 0 and incrementing the next_action_index', function ()
        instance:update()
        assert.spy(action_callback).was_not_called()
        assert.are_equal(0, instance.last_trigger_frame)
        assert.are_equal(1, instance.next_action_index)
      end)

      it('should not call a later action (t=1.02) before the expected time (1.0s)', function ()
        repeat_callback(1.0, function ()
          instance:update()
        end)
        assert.spy(action_callback).was_not_called()
        assert.are_equal(0, instance.last_trigger_frame)
        assert.are_equal(1, instance.next_action_index)
      end)

      it('should call a later action (t=1.02) after the action time has been reached', function ()
        repeat_callback(1.02, function ()
          instance:update()
        end)
        assert.spy(action_callback).was_called(1)
        assert.are_equal(61, instance.last_trigger_frame)
        assert.are_equal(2, instance.next_action_index)
      end)

      it('should end the test once the last action has been applied', function ()
        repeat_callback(1.02, function ()
          instance:update()
        end)
        assert.are_equal(test_states.success, instance.current_state)
        assert.are_equal(2, instance.next_action_index)
      end)

      describe('(with timeout set to 2s and more actions after that, usually unmet conditions)', function ()

        before_each(function ()
          test:add_action(time_trigger(3.0, false, 60), function () end, 'more action')
          test:set_timeout(120)
        end)

        describe('(when next frame is below 120)', function ()

          before_each(function ()
            instance.current_frame = 118
          end)

          it('should call next action (no time out)', function ()
            instance:update()
            assert.are_equal(test_states.running, instance.current_state)
            assert.spy(action_callback).was_called(1)
          end)

        end)

        describe('(when next frame is 120 or above)', function ()

          before_each(function ()
            instance.current_frame = 119
          end)

          it('should time out without calling next action', function ()
            instance:update()
            assert.are_equal(test_states.timeout, instance.current_state)
            assert.spy(action_callback).was_not_called()
          end)

        end)

      end)

    end)

    describe('(after test ended)', function ()

      before_each(function ()
        -- without any action, start should end the test immediately
        instance:start(test)
      end)

      it('should do nothing', function ()
        assert.are_equal(instance.current_state, test_states.success)
        assert.has_no_errors(function () instance:update() end)
        assert.are_equal(instance.current_state, test_states.success)
      end)

    end)

  end)

  describe('initialize', function ()

    it('should set all logger categories (except itest, but that\'s only visible in pico8 build)', function ()
      instance:initialize()
    end)

    it('should set initialized to true', function ()
      instance:initialize()
      assert.is_true(instance.initialized)
    end)

  end)

  describe('check_next_action', function ()

    describe('(with dummy action after 1s)', function ()

      local action_callback = spy.new(function () end)
      local action_callback2 = spy.new(function () end)

      setup(function ()
        -- don't stub a function if the return value matters, as in start
        spy.on(itest_run, "check_end")
      end)

      teardown(function ()
        action_callback:revert()
        action_callback2:revert()
        itest_run.check_end:revert()
      end)

      before_each(function ()
        instance:start(test)
        test:add_action(time_trigger(1.0, false, 60), action_callback, 'action_callback')
      end)

      after_each(function ()
        action_callback:clear()
        action_callback2:clear()
        itest_run.check_end:clear()
      end)

      describe('(when next action index is 1/1)', function ()

        before_each(function ()
          instance.next_action_index = 1
        end)

        describe('(when next action time trigger is not reached yet)', function ()

          before_each(function ()
            -- time trigger uses relative frames, so compare the difference since last trigger to 60
            instance.current_frame = 158
            instance.last_trigger_frame = 100
          end)

          it('should not call the action nor advance the time/index', function ()
            itest_run.check_end:clear()  -- was called on start in before_each
            instance:check_next_action()
            assert.spy(action_callback).was_not_called()
            assert.are_equal(100, instance.last_trigger_frame)
            assert.are_equal(1, instance.next_action_index)
            assert.spy(itest_run.check_end).was_not_called()
          end)

        end)

        describe('(when next action time trigger is reached)', function ()

          before_each(function ()
            -- time trigger uses relative frames, so compare the difference since last trigger to 60
            instance.current_frame = 160
            instance.last_trigger_frame = 100
          end)

          it('should call the action and advance the timeindex', function ()
            itest_run.check_end:clear()  -- was called on start in before_each
            instance:check_next_action()
            assert.spy(action_callback).was_called(1)
            assert.spy(action_callback).was_called_with()
            assert.are_equal(160, instance.last_trigger_frame)
            assert.are_equal(2, instance.next_action_index)
            assert.spy(itest_run.check_end).was_called(1)
            assert.spy(itest_run.check_end).was_called_with(match.ref(instance))
          end)

        end)

      end)

      describe('(when next action index is 2/1)', function ()

        before_each(function ()
          -- we still have the dummy action from the outer scope
          instance.next_action_index = 2  -- we are now at 2/1
        end)

        it('should assert', function ()
          assert.has_error(function ()
            instance:check_next_action()
          end,
          "self.next_action_index (2) is out of bounds for self.current_test.action_sequence (size 1)")
        end)

      end)

      describe('(with 2nd dummy action immediately after the other)', function ()

        describe('(when next action index is 1/1)', function ()

          before_each(function ()
            instance.next_action_index = 1
          end)

          describe('(when next action time trigger is not reached yet)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0.0, false, 60), action_callback2, 'action_callback2')
              instance.current_frame = 158
              instance.last_trigger_frame = 100
            end)

            it('should not call any actions nor advance the time/index', function ()
              itest_run.check_end:clear()  -- was called on start in before_each
              instance:check_next_action()
              assert.spy(action_callback).was_not_called()
              assert.spy(action_callback2).was_not_called()
              assert.are_equal(100, instance.last_trigger_frame)
              assert.are_equal(1, instance.next_action_index)
              assert.spy(itest_run.check_end).was_not_called()
            end)

          end)

          describe('(when next action time trigger is reached)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0, true), action_callback2, 'action_callback2')
              instance.current_frame = 160
              instance.last_trigger_frame = 100
            end)

            it('should call both actions and advance the timeindex by 2', function ()
              itest_run.check_end:clear()  -- was called on start in before_each
              instance:check_next_action()
              assert.spy(action_callback).was_called(1)
              assert.spy(action_callback).was_called_with()
              assert.spy(action_callback2).was_called(1)  -- thx to action chaining when next action time is 0
              assert.spy(action_callback2).was_called_with()
              assert.are_equal(160, instance.last_trigger_frame)
              assert.are_equal(3, instance.next_action_index)  -- after action 2
              assert.spy(itest_run.check_end).was_called(2)     -- checked after each action
              assert.spy(itest_run.check_end).was_called_with(match.ref(instance))
            end)

          end)

        end)

      end)

      describe('(with 2nd dummy action some frames after the other)', function ()

        describe('(when next action index is 1/1)', function ()

          before_each(function ()
            instance.next_action_index = 1
          end)

          describe('(when next action time trigger is not reached yet)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0.2, false, 60), action_callback2, 'action_callback2')
              instance.current_frame = 158
              instance.last_trigger_frame = 100
            end)

            it('should not call any actions nor advance the time/index', function ()
              itest_run.check_end:clear()  -- was called on start in before_each
              instance:check_next_action()
              assert.spy(action_callback).was_not_called()
              assert.spy(action_callback2).was_not_called()
              assert.are_equal(100, instance.last_trigger_frame)
              assert.are_equal(1, instance.next_action_index)
              assert.spy(itest_run.check_end).was_not_called()
            end)

          end)

          describe('(when next action time trigger is reached)', function ()

            before_each(function ()
              -- time trigger uses relative frames, so compare the difference since last trigger to 60
              test:add_action(time_trigger(0.2, false, 60), action_callback2, 'action_callback2')
              instance.current_frame = 160
              instance.last_trigger_frame = 100
            end)

            it('should call only the first action and advance the timeindex', function ()
              itest_run.check_end:clear()  -- was called on start in before_each
              instance:check_next_action()
              assert.spy(action_callback).was_called(1)
              assert.spy(action_callback).was_called_with()
              assert.spy(action_callback2).was_not_called()  -- at least 1 frame before action2, no action chaining
              assert.are_equal(160, instance.last_trigger_frame)
              assert.are_equal(2, instance.next_action_index)
              assert.spy(itest_run.check_end).was_called(1)
              assert.spy(itest_run.check_end).was_called_with(match.ref(instance))
            end)

          end)

        end)

      end)

    end)

    describe('(with empty action)', function ()

      before_each(function ()
        -- empty actions are useful to just wait until the test end and delay the final assertion
        test:add_action(time_trigger(1, true), nil, 'empty action')
      end)

      it('should recognize next empty action and do nothing', function ()
        instance:start(test)
        instance.current_frame = 2  -- to trigger action to do at end of frame 1

        assert.has_no_errors(function ()
          instance:check_next_action()
        end)
      end)

    end)

  end)

  describe('check_end', function ()

    before_each(function ()
      instance:start(test)
    end)

    describe('(when no actions left)', function ()

      describe('(when no final assertion)', function ()

        it('should make test end immediately with success and return true', function ()
          local result = instance:check_end(test)
          assert.is_true(result)
          assert.are_same({test_states.success, nil},
            {instance.current_state, instance.current_message})
        end)

      end)

      describe('(when final assertion passes)', function ()

        before_each(function ()
          test.final_assertion = function (app)
            return true
          end
        end)

        it('should check the final assertion immediately, end with success and return true', function ()
          local result = instance:check_end(test)
          assert.is_true(result)
          assert.are_same({test_states.success, nil},
            {instance.current_state, instance.current_message})
        end)

      end)

      describe('(when final assertion passes)', function ()

        before_each(function ()
          test.final_assertion = function (app)
            return false, "error message"
          end
        end)

        it('should check the final assertion immediately, end with failure and return true', function ()
          local result = instance:check_end(test)
          assert.is_true(result)
          assert.are_equal(test_states.failure, instance.current_state)
        end)

      end)

    end)

    describe('(when some actions left)', function ()

      before_each(function ()
        test:add_action(time_trigger(1.0, false, 60), function () end, 'check_end_test_action')
      end)

      it('should return false', function ()
        assert.is_false(instance:check_end(test))
      end)

    end)

  end)

  describe('stop', function ()

    it('(no test started) should still have no test, without error', function ()
      instance:stop(test)
      assert.is_nil(instance.current_test)
    end)

    describe('(test started)', function ()

      before_each(function ()
        instance:start(test)
      end)

      it('should reset the current test', function ()
        instance:stop(test)
        assert.is_nil(instance.current_test)
      end)

      it('should reset state vars', function ()
        instance:stop(test)
        assert.are_same({0, 0, 1, test_states.none}, {
          instance.current_frame,
          instance.last_trigger_frame,
          instance.next_action_index,
          instance.current_state
        })
      end)

      describe('(when teardown is set)', function ()

        before_each(function ()
          test.teardown = spy.new(function () end)
        end)

        it('should call teardown', function ()
          instance:stop(test)
          assert.spy(test.teardown).was_called(1)
          assert.spy(test.teardown).was_called_with(app)
        end)

      end)

    end)

  end)

end)
