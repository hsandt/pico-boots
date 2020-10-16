require("engine/test/bustedhelper")
local itest_manager = require("engine/test/itest_manager")

local gameapp = require("engine/application/gameapp")
local integration_test = require("engine/test/integration_test")
local itest_run = require("engine/test/itest_run")
local test_states = itest_run.test_states
local scripted_action = require("engine/test/scripted_action")
local time_trigger = require("engine/test/time_trigger")

describe('itest_manager', function ()

  describe('init', function ()

    it('should create a singleton instance with empty itests and an itest_run referring to the manager itself', function ()
      assert.are_same({{}, itest_run(itest_manager), 0}, {itest_manager.itests, itest_manager.itest_run, itest_manager.current_itest_index})
    end)

  end)

  describe('(with mock app)', function ()

    local mock_app = gameapp(60)

    before_each(function ()
      itest_manager.itest_run.app = mock_app
    end)

    after_each(function ()
      itest_manager:init()
    end)

    describe('register_itest', function ()

      it('should register a new test', function ()
        local function setup_fn(app) end
        local function teardown_fn(app) end
        local function action1() end
        local function action2() end
        local function action3() end
        local function action4() end
        local function final_assert_fn() end
        itest_manager:register_itest('test 1', {'titlemenu'}, function ()
          setup_callback(setup_fn)
          teardown_callback(teardown_fn)
          act(action1)  -- test immediate action
          wait(0.5)
          wait(0.6)     -- test closing previous wait
          act(action2)  -- test action with previous wait
          act(action3)  -- test immediate action
          add_action(time_trigger(1.0, false, 60), action4)  -- test retro-compatible function
          wait(0.7)     -- test wait-action closure
          final_assert(final_assert_fn)
        end)
        local created_itest = itest_manager.itests[1]
        assert.are_same({
            'test 1',
            {'titlemenu'},
            setup_fn,
            teardown_fn,
            {
              scripted_action(time_trigger(0.0, false, 60), action1),
              scripted_action(time_trigger(0.5, false, 60), dummy),
              scripted_action(time_trigger(0.6, false, 60), action2),
              scripted_action(time_trigger(0.0, false, 60), action3),
              scripted_action(time_trigger(1.0, false, 60), action4),
              scripted_action(time_trigger(0.7, false, 60), dummy)
            },
            final_assert_fn
          },
          {
            created_itest.name,
            created_itest.active_gamestates,
            created_itest.setup,
            created_itest.teardown,
            created_itest.action_sequence,
            created_itest.final_assertion
          })
      end)

    end)

    describe('register', function ()

      it('should register a new test', function ()
        local itest = integration_test('test 1', {'titlemenu'})
        itest_manager:register(itest)
        assert.are_equal(itest, itest_manager.itests[1])
      end)

      it('should register a 2nd test', function ()
        local itest = integration_test('test 1', {'titlemenu'})
        local itest2 = integration_test('test 2', {'titlemenu'})
        itest_manager:register(itest)
        itest_manager:register(itest2)
        assert.are_same({itest, itest2}, itest_manager.itests)
      end)

    end)

    describe('init_game_and_start_by_index', function ()

      local itest

      setup(function ()
        stub(itest_run, "init_game_and_start")
      end)

      teardown(function ()
        itest_run.init_game_and_start:revert()
      end)

      after_each(function ()
        itest_run.init_game_and_start:clear()
      end)


      it('should do nothing when no itests are registered', function ()
        itest_manager.current_itest_index = 0

        itest_manager:init_game_and_start_by_index(1)

        assert.spy(itest_run.init_game_and_start).was_not_called()
      end)

      describe('1 itest registered)', function ()

        before_each(function ()
          -- register 1 mock itest (relies on register implementation being correct)
          itest = integration_test('test 1', {'titlemenu'})
          itest_manager:register(itest)
        end)

        it('should delegate to itest runner', function ()
          itest_manager:init_game_and_start_by_index(1)
          assert.spy(itest_run.init_game_and_start).was_called(1)
          assert.spy(itest_run.init_game_and_start).was_called_with(match.ref(itest_manager.itest_run), itest)
        end)

        it('should assert if the index is invalid', function ()
          assert.has_error(function ()
            itest_manager:init_game_and_start_by_index(2)
          end,
          "itest_manager:init_game_and_start_by_index: index is 2 but only 1 were registered.")
        end)

      end)

    end)

    describe('init_game_and_start_itest_by_relative_index', function ()

      local itest1
      local itest2

      setup(function ()
        stub(itest_manager, "init_game_and_start_by_index")
        stub(itest_run, "stop_and_reset_game")
      end)

      teardown(function ()
        itest_manager.init_game_and_start_by_index:revert()
        itest_run.stop_and_reset_game:revert()
      end)

      after_each(function ()
        itest_manager.init_game_and_start_by_index:clear()
        itest_run.stop_and_reset_game:clear()
      end)

      it('should do nothing when no itests are registered', function ()
        itest_manager.current_itest_index = 0

        itest_manager:init_game_and_start_itest_by_relative_index(1)

        assert.spy(itest_manager.init_game_and_start_by_index).was_not_called()
      end)

      describe('(2 itests registered)', function ()

        before_each(function ()
          -- register 2 mock itests (relies on register implementation being correct)
          itest1 = integration_test('test 1', {'titlemenu'})
          itest2 = integration_test('test 2', {'ingame'})
          itest_manager:register(itest1)
          itest_manager:register(itest2)
        end)

        it('index 1 + 1 => 2', function ()
          itest_manager.current_itest_index = 1

          itest_manager:init_game_and_start_itest_by_relative_index(1)

          assert.spy(itest_manager.init_game_and_start_by_index).was_called(1)
          assert.spy(itest_manager.init_game_and_start_by_index).was_called_with(match.ref(itest_manager), 2)
        end)

        it('index 2 - 1 => 1', function ()
          itest_manager.current_itest_index = 2

          itest_manager:init_game_and_start_itest_by_relative_index(-1)

          assert.spy(itest_manager.init_game_and_start_by_index).was_called(1)
          assert.spy(itest_manager.init_game_and_start_by_index).was_called_with(match.ref(itest_manager), 1)
        end)

        it('index 1 + 10 => 2 (clamped)', function ()
          itest_manager.current_itest_index = 1

          itest_manager:init_game_and_start_itest_by_relative_index(10)

          assert.spy(itest_manager.init_game_and_start_by_index).was_called(1)
          assert.spy(itest_manager.init_game_and_start_by_index).was_called_with(match.ref(itest_manager), 2)
        end)

        it('index 2 - 10 => 1 (clamped)', function ()
          itest_manager.current_itest_index = 2

          itest_manager:init_game_and_start_itest_by_relative_index(-10)

          assert.spy(itest_manager.init_game_and_start_by_index).was_called(1)
          assert.spy(itest_manager.init_game_and_start_by_index).was_called_with(match.ref(itest_manager), 1)
        end)

        it('index 1 - 10 => 1 (stuck)', function ()
          itest_manager.current_itest_index = 1

          itest_manager:init_game_and_start_itest_by_relative_index(-10)

          assert.spy(itest_manager.init_game_and_start_by_index).was_not_called()
        end)

        it('index 2 + 10 => 2 (stuck)', function ()
          itest_manager.current_itest_index = 2

          itest_manager:init_game_and_start_itest_by_relative_index(10)

          assert.spy(itest_manager.init_game_and_start_by_index).was_not_called()
        end)

        it('no current test => no stop/reset even if index change occurs', function ()
          itest_manager.current_itest_index = 1

          itest_manager:init_game_and_start_itest_by_relative_index(1)

          assert.spy(itest_run.stop_and_reset_game).was_not_called()
        end)

        it('no current test => no stop/reset even if index change occurs', function ()
          itest_manager.current_itest_index = 1

          itest_manager:init_game_and_start_itest_by_relative_index(1)

          assert.spy(itest_run.stop_and_reset_game).was_not_called()
        end)

        it('current test running => stop/reset it if index change occurs', function ()
          itest_manager.itest_run.current_test = itest1
          itest_manager.current_itest_index = 1

          itest_manager:init_game_and_start_itest_by_relative_index(1)

          assert.spy(itest_run.stop_and_reset_game).was_called(1)
          assert.spy(itest_run.stop_and_reset_game).was_called_with(match.ref(itest_manager.itest_run))
        end)

      end)

    end)

    describe('init_game_and_restart_itest', function ()

      local itest1

      setup(function ()
        stub(itest_run, "stop_and_reset_game", function ()
          -- simulate one of the most problematic aspect, that stop will clear the current test
          --  to make sure that you store the current itest index in a var before calling stop
          itest_manager.current_itest_index = 0
        end)
        stub(itest_manager, "init_game_and_start_by_index")
      end)

      teardown(function ()
        itest_run.stop_and_reset_game:revert()
        itest_manager.init_game_and_start_by_index:revert()
      end)

      before_each(function ()
        -- register 1 mock itest (relies on register implementation being correct)
        itest1 = integration_test('test 1', {'titlemenu'})
        itest_manager:register(itest1)
      end)

      after_each(function ()
        itest_run.stop_and_reset_game:clear()
        itest_manager.init_game_and_start_by_index:clear()
      end)

      it('restart itest 1', function ()
        -- we're using the test directly not the index, otherwise set:
        itest_manager.current_itest_index = 1
        itest_manager.itest_run.current_test = itest1

        itest_manager:init_game_and_restart_itest()

        assert.spy(itest_run.stop_and_reset_game).was_called(1)
        assert.spy(itest_run.stop_and_reset_game).was_called_with(match.ref(itest_manager.itest_run))
        assert.spy(itest_manager.init_game_and_start_by_index).was_called(1)
        assert.spy(itest_manager.init_game_and_start_by_index).was_called_with(match.ref(itest_manager), 1)
      end)

      it('no current test => no stop nor restart', function ()
        -- we're using the test directly not the index, otherwise set:
        itest_manager.current_itest_index = 0
        -- optional, for clarity
        itest_manager.itest_run.current_test = nil

        itest_manager:init_game_and_restart_itest()

        assert.spy(itest_run.stop_and_reset_game).was_not_called()
        assert.spy(itest_manager.init_game_and_start_by_index).was_not_called()
      end)

    end)

    describe('init_game_and_start_next_itest', function ()

      setup(function ()
        stub(itest_manager, "init_game_and_start_itest_by_relative_index")
      end)

      teardown(function ()
        itest_manager.init_game_and_start_itest_by_relative_index:revert()
      end)

      after_each(function ()
        itest_manager.init_game_and_start_itest_by_relative_index:clear()
      end)

      it('should start next itest, i.e. itest with relative index +1', function ()
        itest_manager:init_game_and_start_next_itest()

        assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called(1)
        assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called_with(match.ref(itest_manager), 1)
      end)

    end)

    describe('handle_input', function ()

      setup(function ()
        stub(itest_manager, "init_game_and_start_itest_by_relative_index")
        stub(itest_manager, "init_game_and_start_next_itest")
        stub(itest_manager, "init_game_and_restart_itest")
        stub(itest_run, "step_game_and_test")
        stub(itest_run, "toggle_pause")
      end)

      teardown(function ()
        itest_manager.init_game_and_start_itest_by_relative_index:revert()
        itest_manager.init_game_and_start_next_itest:revert()
        itest_manager.init_game_and_restart_itest:revert()
        itest_run.step_game_and_test:revert()
        itest_run.toggle_pause:revert()
      end)


      after_each(function ()
        clear_table(pico8.keypressed[0])
        pico8.keypressed.counter = 0

        itest_manager.init_game_and_start_itest_by_relative_index:clear()
        itest_manager.init_game_and_start_next_itest:clear()
        itest_manager.init_game_and_restart_itest:clear()
        itest_run.step_game_and_test:clear()
        itest_run.toggle_pause:clear()
      end)

      it('no itests => do nothing even when presssing keys', function ()
        pico8.keypressed[0][button_ids.left] = true

        itest_manager:handle_input()

        assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_not_called()
      end)

      describe('with 2 itests registered', function ()

        local itest1
        local itest2

        before_each(function ()
          -- register 2 mock itests (relies on register implementation being correct)
          itest1 = integration_test('test 1', {'titlemenu'})
          itest2 = integration_test('test 2', {'ingame'})
          itest_manager:register(itest1)
          itest_manager:register(itest2)
        end)

        it('press left => start previous', function ()
          pico8.keypressed[0][button_ids.left] = true  -- pressed
          pico8.keypressed.counter = 1  -- *just* pressed

          itest_manager:handle_input()

          assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called(1)
          assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called_with(match.ref(itest_manager), -1)
        end)

        it('press right => start next', function ()
          pico8.keypressed[0][button_ids.right] = true
          pico8.keypressed.counter = 1  -- *just* pressed

          itest_manager:handle_input()

          assert.spy(itest_manager.init_game_and_start_next_itest).was_called(1)
          assert.spy(itest_manager.init_game_and_start_next_itest).was_called_with(match.ref(itest_manager))
        end)

        it('press up => start previous', function ()
          pico8.keypressed[0][button_ids.up] = true
          pico8.keypressed.counter = 1  -- *just* pressed

          itest_manager:handle_input()

          assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called(1)
          assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called_with(match.ref(itest_manager), -10)
        end)

        it('press down => start previous', function ()
          pico8.keypressed[0][button_ids.down] = true
          pico8.keypressed.counter = 1  -- *just* pressed

          itest_manager:handle_input()

          assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called(1)
          assert.spy(itest_manager.init_game_and_start_itest_by_relative_index).was_called_with(match.ref(itest_manager), 10)
        end)

        it('press o => start previous', function ()
          pico8.keypressed[0][button_ids.o] = true
          pico8.keypressed.counter = 1  -- *just* pressed

          itest_manager:handle_input()

          assert.spy(itest_manager.init_game_and_restart_itest).was_called(1)
          assert.spy(itest_manager.init_game_and_restart_itest).was_called_with(match.ref(itest_manager))
        end)

        it('press x => toggle pause', function ()
          pico8.keypressed[0][button_ids.x] = true
          pico8.keypressed.counter = 1  -- *just* pressed

          itest_manager:handle_input()

          assert.spy(itest_run.toggle_pause).was_called(1)
          assert.spy(itest_run.toggle_pause).was_called_with(match.ref(itest_manager.itest_run))
        end)

        describe('(itest paused)', function ()

          it('press right => step 1x', function ()
            itest_manager.itest_run.current_state = test_states.paused
            pico8.keypressed[0][button_ids.right] = true
            pico8.keypressed.counter = 1  -- *just* pressed

            itest_manager:handle_input()

            assert.spy(itest_run.step_game_and_test).was_called(1)
            assert.spy(itest_run.step_game_and_test).was_called_with(match.ref(itest_manager.itest_run))
          end)

          it('press down => step 10x', function ()
            itest_manager.itest_run.current_state = test_states.paused
            pico8.keypressed[0][button_ids.down] = true
            pico8.keypressed.counter = 1  -- *just* pressed

            itest_manager:handle_input()

            assert.spy(itest_run.step_game_and_test).was_called(10)
            assert.spy(itest_run.step_game_and_test).was_called_with(match.ref(itest_manager.itest_run))
          end)

          it('press o => start previous', function ()
            itest_manager.itest_run.current_state = test_states.paused
            pico8.keypressed[0][button_ids.o] = true
            pico8.keypressed.counter = 1  -- *just* pressed

            itest_manager:handle_input()

            assert.spy(itest_manager.init_game_and_restart_itest).was_called(1)
            assert.spy(itest_manager.init_game_and_restart_itest).was_called_with(match.ref(itest_manager))
          end)

          it('press x => toggle pause', function ()
            itest_manager.itest_run.current_state = test_states.paused
            pico8.keypressed[0][button_ids.x] = true
            pico8.keypressed.counter = 1  -- *just* pressed

            itest_manager:handle_input()

            assert.spy(itest_run.toggle_pause).was_called(1)
            assert.spy(itest_run.toggle_pause).was_called_with(match.ref(itest_manager.itest_run))
          end)

        end)

      end)

    end)


    describe('update', function ()

      setup(function ()
        stub(itest_run, "update_game_and_test")
      end)

      teardown(function ()
        itest_run.update_game_and_test:revert()
      end)

      after_each(function ()
        itest_run.update_game_and_test:clear()
      end)

      it('should call update_game_and_test on itest_run', function ()
        itest_manager:update()

        assert.spy(itest_run.update_game_and_test).was_called(1)
        assert.spy(itest_run.update_game_and_test).was_called_with(match.ref(itest_manager.itest_run))
      end)

    end)

    describe('stop_and_reset_game', function ()

      setup(function ()
        stub(itest_run, "stop_and_reset_game")
      end)

      teardown(function ()
        itest_run.stop_and_reset_game:revert()
      end)

      after_each(function ()
        itest_run.stop_and_reset_game:clear()
      end)

      it('should call stop_and_reset_game on itest_run', function ()
        itest_manager:stop_and_reset_game()

        assert.spy(itest_run.stop_and_reset_game).was_called(1)
        assert.spy(itest_run.stop_and_reset_game).was_called_with(match.ref(itest_manager.itest_run))
      end)

    end)

    describe('draw', function ()

      setup(function ()
        stub(itest_run, "draw_game")
        stub(itest_manager, "draw_test_info")
      end)

      teardown(function ()
        itest_run.draw_game:revert()
        itest_manager.draw_test_info:revert()
      end)

      after_each(function ()
        itest_run.draw_game:clear()
        itest_manager.draw_test_info:clear()
      end)

      it('should draw the gameapp via itest_run and test info above', function ()
        itest_manager:draw()

        assert.spy(itest_run.draw_game).was_called(1)
        assert.spy(itest_run.draw_game).was_called_with(match.ref(itest_manager.itest_run))
        assert.spy(itest_manager.draw_test_info).was_called(1)
        assert.spy(itest_manager.draw_test_info).was_called_with(match.ref(itest_manager))
      end)

    end)

    describe('draw_test_info', function ()

      describe('(stubbing api.print)', function ()

        setup(function ()
          stub(api, "print")
        end)

        teardown(function ()
          api.print:revert()
        end)

        after_each(function ()
          api.print:clear()
          itest_manager:init()
        end)

        it('(some itests registered) should draw "no itest running"', function ()
          itest_manager.itests = {integration_test('test 1', {'titlemenu'})}

          itest_manager:draw()

          assert.spy(api.print).was_called(1)
          assert.spy(api.print).was_called_with("no itest running", 8, 8, colors.white)
        end)

        it('(no itests at all) should draw "no itests found"', function ()
          itest_manager:draw()

          assert.spy(api.print).was_called(1)
          assert.spy(api.print).was_called_with("no itests found", 8, 8, colors.white)
        end)

        describe('(when current test is set)', function ()

          before_each(function ()
            local itest1 = integration_test('test 1', {'titlemenu'})
            itest_manager.itest_run.current_test = itest1
            itest_manager.itest_run.current_state = test_states.running
          end)

          it('#solo should draw information on the current test', function ()
            printh("itest_manager.itest_run: "..nice_dump(itest_manager.itest_run))
            itest_manager:draw()
            assert.spy(api.print).was_called(2)
          end)

        end)

      end)

    end)

  end)

  describe('get_test_state_color', function ()

    it('should return white for none', function ()
      assert.are_equal(colors.white, itest_manager.get_test_state_color(test_states.none))
    end)

    it('should return white for running', function ()
      assert.are_equal(colors.white, itest_manager.get_test_state_color(test_states.running))
    end)

    it('should return orange for paused', function ()
      assert.are_equal(colors.orange, itest_manager.get_test_state_color(test_states.paused))
    end)

    it('should return green for success', function ()
      assert.are_equal(colors.green, itest_manager.get_test_state_color(test_states.success))
    end)

    it('should return red for failure', function ()
      assert.are_equal(colors.red, itest_manager.get_test_state_color(test_states.failure))
    end)

    it('should return dark purple for timeout', function ()
      assert.are_equal(colors.dark_purple, itest_manager.get_test_state_color(test_states.timeout))
    end)

  end)

end)
