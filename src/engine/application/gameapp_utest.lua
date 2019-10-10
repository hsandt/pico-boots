require("engine/test/bustedhelper")
local gameapp = require("engine/application/gameapp")

local coroutine_runner = require("engine/application/coroutine_runner")
local flow = require("engine/application/flow")
local manager = require("engine/application/manager")
local input = require("engine/input/input")
local ui = require("engine/ui/ui")

describe('gameapp', function ()

  describe('init', function ()

    it('should set empty managers table, new coroutine runner, nil initial gamestate', function ()
      local app = gameapp(30)
      assert.are_same({{}, coroutine_runner(), 30, 1 / 30, nil},
        {app.managers, app.coroutine_runner, app.fps, app.delta_time, app.initial_gamestate})
    end)

  end)

  describe('(with default app using 30 fps)', function ()

    local app

    local mock_manager_class1 = derived_class(manager)
    mock_manager_class1.type = ':mock1'
    mock_manager_class1.start = spy.new(function () end)
    mock_manager_class1.update = spy.new(function () end)
    mock_manager_class1.render = spy.new(function () end)

    local mock_manager_class2 = derived_class(manager)
    mock_manager_class2.type = ':mock2'
    mock_manager_class2.start = spy.new(function () end)
    mock_manager_class2.update = spy.new(function () end)
    mock_manager_class2.render = spy.new(function () end)

    before_each(function ()
      app = gameapp(30)
      mock_manager1 = mock_manager_class1(app)
      mock_manager2 = mock_manager_class2(app)
      mock_manager2.active = false  -- to test no update/render
    end)

    describe('register_managers', function ()

      it('should register each manager passed in variadic arg', function ()
        app:register_managers(mock_manager1, mock_manager2)
        assert.are_same({[':mock1'] = mock_manager1, [':mock2'] = mock_manager2}, app.managers)
      end)

    end)

    describe('register_gamestates', function ()

      -- we won't even try calling on_enter, etc. so empty tables are enough
      local dummy_state1 = {}
      local dummy_state2 = {}

      setup(function ()
        stub(flow, "add_gamestate")
      end)

      teardown(function ()
        flow.add_gamestate:revert()
      end)

      before_each(function ()
        -- quick way to override method
        -- without having to derive a class from gameapp, then instantiate it
        -- (normally we should inject the app with my_state(self) each time)
        function app:instantiate_gamestates()
          return {dummy_state1, dummy_state2}
        end
      end)

      it('should add all gamestates returned by instantiate_gamestates to flow', function ()
        app:register_gamestates()

        local s1 = assert.spy(flow.add_gamestate)
        s1.was_called(2)
        s1.was_called_with(match.ref(flow), match.ref(dummy_state1))
        s1.was_called_with(match.ref(flow), match.ref(dummy_state1))
      end)

    end)

    describe('(with mock_manager1 and mock_manager2 registered)', function ()

      before_each(function ()
        -- relies on register_managers being correct
        app:register_managers(mock_manager1, mock_manager2)
      end)

      describe('start', function ()

        setup(function ()
          spy.on(gameapp, "register_gamestates")
          spy.on(gameapp, "on_pre_start")
          spy.on(gameapp, "on_post_start")
          stub(flow, "query_gamestate_type")
        end)

        teardown(function ()
          gameapp.register_gamestates:revert()
          gameapp.on_pre_start:revert()
          gameapp.on_post_start:revert()
          flow.query_gamestate_type:revert()
        end)

        after_each(function ()
          gameapp.register_gamestates:clear()
          gameapp.on_pre_start:clear()
          gameapp.on_post_start:clear()
          flow.query_gamestate_type:clear()

          mock_manager1.start:clear()
          mock_manager2.start:clear()
        end)

        it('should assert if initial_gamestate is not set', function ()
          assert.has_error(function ()
            app:start()
          end, "gameapp:start: gameapp.initial_gamestate is not set")
        end)

        describe('(initial gamestate set to "dummy")', function ()

          before_each(function ()
            app.initial_gamestate = "dummy"
          end)

          it('should call start on_pre_start', function ()
            app:start()

            local s = assert.spy(gameapp.on_pre_start)
            s.was_called(1)
            s.was_called_with(match.ref(app))
          end)

          it('should call register_gamestates', function ()
            app:start()

            assert.spy(gameapp.register_gamestates).was_called(1)
            assert.spy(gameapp.register_gamestates).was_called_with(match.ref(app))
          end)

          it('should call flow:query_gamestate_type with self.initial_gamestate', function ()
            app.initial_gamestate = "dummy_state"

            app:start()

            local s = assert.spy(flow.query_gamestate_type)
            s.was_called(1)
            s.was_called_with(match.ref(flow), "dummy_state")
          end)

          it('should call start on each manager', function ()
            app:start()

            local s1 = assert.spy(mock_manager1.start)
            s1.was_called(1)
            s1.was_called_with(match.ref(mock_manager1))

            local s2 = assert.spy(mock_manager2.start)
            s2.was_called(1)
            s2.was_called_with(match.ref(mock_manager2))
          end)

          it('should call start on_post_start', function ()
            app:start()

            local s = assert.spy(gameapp.on_post_start)
            s.was_called(1)
            s.was_called_with(match.ref(app))
          end)

        end)  -- (initial gamestate set to "dummy")

      end)

      describe('reset', function ()

        setup(function ()
          stub(flow, "init")
          spy.on(gameapp, "on_reset")
        end)

        teardown(function ()
          flow.init:revert()
          gameapp.on_reset:revert()
        end)

        after_each(function ()
          flow.init:clear()
          gameapp.on_reset:clear()
        end)

        it('should call flow:init', function ()
          app:reset()

          assert.spy(flow.init).was_called(1)
          assert.spy(flow.init).was_called_with(match.ref(flow))
        end)

        it('should call on_reset', function ()
          app:reset()

          assert.spy(gameapp.on_reset).was_called(1)
          assert.spy(gameapp.on_reset).was_called_with(match.ref(app))
        end)

      end)

      describe('update', function ()

        setup(function ()
          stub(input, "process_players_inputs")
          stub(coroutine_runner, "update_coroutines")
          stub(flow, "update")
          spy.on(gameapp, "on_update")
        end)

        teardown(function ()
          input.process_players_inputs:revert()
          coroutine_runner.update_coroutines:revert()
          flow.update:revert()
          gameapp.on_update:revert()
        end)

        after_each(function ()
          input.process_players_inputs:clear()
          coroutine_runner.update_coroutines:clear()
          flow.update:clear()
          gameapp.on_update:clear()

          mock_manager1.update:clear()
          mock_manager2.update:clear()
        end)

        it('should call input:process_players_inputs', function ()
          app:update()

          local s = assert.spy(input.process_players_inputs)
          s.was_called(1)
          s.was_called_with(match.ref(input))
        end)

        it('should update coroutines via coroutine runner', function ()
          app:update()

          local s = assert.spy(coroutine_runner.update_coroutines)
          s.was_called(1)
          s.was_called_with(match.ref(app.coroutine_runner))
        end)

        -- bugfix history:
        -- + forget self. in front of managers
        it('should update all registered managers that are active', function ()
          app:update()

          local s1 = assert.spy(mock_manager1.update)
          s1.was_called(1)
          s1.was_called_with(match.ref(mock_manager1))

          local s2 = assert.spy(mock_manager2.update)
          s2.was_not_called()
        end)

        it('should update the flow', function ()
          app:update()

          local s2 = assert.spy(flow.update)
          s2.was_called(1)
          s2.was_called_with(match.ref(flow))
        end)

        it('should call on_update', function ()
          app:update()

          local s2 = assert.spy(app.on_update)
          s2.was_called(1)
          s2.was_called_with(match.ref(app))
        end)

      end)

      describe('draw', function ()

        setup(function ()
          stub(_G, "cls")
          stub(flow, "render")
        end)

        teardown(function ()
          cls:revert()
          flow.render:revert()
        end)

        after_each(function ()
          cls:clear()
          flow.render:clear()

          mock_manager1.render:clear()
          mock_manager2.render:clear()
        end)

        it('should clear screen', function ()
          app:draw()
          assert.spy(cls).was_called(1)
        end)

        -- bugfix history:
        -- + forget self. in front of managers
        it('should render all registered managers that are active', function ()
          app:draw()

          local s1 = assert.spy(mock_manager1.render)
          s1.was_called(1)
          s1.was_called_with(match.ref(mock_manager1))
          local s2 = assert.spy(mock_manager2.render)
          s2.was_not_called()
        end)

        it('should call flow:render', function ()
          app:draw()
          local s = assert.spy(flow.render)
          s.was_called(1)
          s.was_called_with(match.ref(flow))
        end)

      end)

    end)  -- (with mock_manager1 and mock_manager2 registered)

    describe('start_coroutine', function ()

      local function coroutine_fun(arg)
        yield()
      end

      setup(function ()
        stub(coroutine_runner, "start_coroutine")
      end)

      teardown(function ()
        coroutine_runner.start_coroutine:revert()
      end)

      it('should delegate start to coroutine runner', function ()
        app:start_coroutine(coroutine_fun, 99)

        local s = assert.spy(coroutine_runner.start_coroutine)
        s.was_called(1)
        s.was_called_with(match.ref(app.coroutine_runner), coroutine_fun, 99)
      end)

    end)

    describe('stop_all_coroutines', function ()

      local function coroutine_fun(arg)
        yield()
      end

      setup(function ()
        stub(coroutine_runner, "stop_all_coroutines")
      end)

      teardown(function ()
        coroutine_runner.stop_all_coroutines:revert()
      end)

      it('should delegate stop to coroutine runner', function ()
        app:stop_all_coroutines()

        local s = assert.spy(coroutine_runner.stop_all_coroutines)
        s.was_called(1)
        s.was_called_with(match.ref(app.coroutine_runner))
      end)

    end)

    describe('yield_delay_s', function ()

      -- we won't even try calling on_enter, etc. so empty tables are enough
      local dummy_state1 = {}
      local dummy_state2 = {}

      setup(function ()
        stub(_G, "yield_delay")
      end)

      teardown(function ()
        yield_delay:revert()
      end)

      after_each(function ()
        yield_delay:clear()
      end)

      it('should call yield_delay with the equivalent in frames (ceiled)', function ()
        app:yield_delay_s(1)

        local s = assert.spy(yield_delay)
        s.was_called(1)
        s.was_called_with(30)
      end)

      it('should call yield_delay with the equivalent in frames, ceiled', function ()
        app:yield_delay_s(0.15)

        local s = assert.spy(yield_delay)
        s.was_called(1)
        s.was_called_with(5)
      end)

    end)

  end)  -- (with default app)

end)
