require("engine/test/bustedhelper")
local gameapp = require("engine/application/gameapp")

local coroutine_runner = require("engine/application/coroutine_runner")
local flow = require("engine/application/flow")
local manager = require("engine/application/manager")
local input = require("engine/input/input")

describe('gameapp', function ()

  describe('init', function ()

    it('should set empty managers table, new coroutine runner, nil initial gamestate', function ()
      local app = gameapp(30)
      assert.are_same({{}, coroutine_runner(), 30, 1 / 30, nil,
          false  -- #debug_menu
        },
        {app.managers, app.coroutine_runner, app.fps, app.delta_time, app.initial_gamestate,
          app.debug_paused  -- #debug_menu
        })
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
    mock_manager_class2.initially_active = false  -- to test no update/render
    mock_manager_class2.start = spy.new(function () end)
    mock_manager_class2.update = spy.new(function () end)
    mock_manager_class2.render = spy.new(function () end)

    before_each(function ()
      app = gameapp(30)
      mock_manager1 = mock_manager_class1()
      mock_manager2 = mock_manager_class2()
    end)

    describe('instantiate_managers', function ()

      it('should return {} with default implementation', function ()
        assert.are_same({}, app:instantiate_managers())
      end)

    end)

    describe('register_managers', function ()

      it('should inject itself as app in each manager', function ()
        app:register_managers({mock_manager1, mock_manager2})
        assert.are_equal(app, mock_manager1.app)
        assert.are_equal(app, mock_manager2.app)
      end)

      it('should register each manager', function ()
        app:register_managers({mock_manager1, mock_manager2})
        assert.are_same({[':mock1'] = mock_manager1, [':mock2'] = mock_manager2}, app.managers)
      end)

    end)

    describe('instantiate_and_register_managers', function ()

      local fake_manager1 = {"manager1"}
      local fake_manager2 = {"manager2"}

      setup(function ()
        stub(gameapp, "register_managers")
      end)

      teardown(function ()
        gameapp.register_managers:revert()
      end)

      before_each(function ()
        -- quick way to override method
        -- without having to derive a class from gameapp, then instantiate it
        function app:instantiate_managers()
          return {fake_manager1, fake_manager2}
        end
      end)

      it('should register all the managers returned by instantiate_managers', function ()
        app:instantiate_and_register_managers()

        local s = assert.spy(gameapp.register_managers)
        s.was_called(1)
        s.was_called_with(match.ref(app), {{"manager1"}, {"manager2"}})
      end)

    end)

    describe('instantiate_gamestates', function ()

      it('should return {} with default implementation', function ()
        assert.are_same({}, app:instantiate_gamestates())
      end)

    end)

    describe('register_gamestates', function ()

      local fake_gamestate1
      local fake_gamestate2

      setup(function ()
        stub(flow, "add_gamestate")
      end)

      teardown(function ()
        flow.add_gamestate:revert()
      end)

      before_each(function ()
        fake_gamestate1 = {"gamestate1"}
        fake_gamestate2 = {"gamestate2"}
      end)

      after_each(function ()
        flow.add_gamestate:clear()
      end)

      it('should inject itself as app in each gamestate', function ()
        app:register_gamestates({fake_gamestate1, fake_gamestate2})

        assert.are_equal(app, fake_gamestate1.app)
        assert.are_equal(app, fake_gamestate2.app)
      end)

      it('should add all gamestates returned by instantiate_gamestates to flow', function ()
        app:register_gamestates({fake_gamestate1, fake_gamestate2})

        local s1 = assert.spy(flow.add_gamestate)
        s1.was_called(2)
        s1.was_called_with(match.ref(flow), match.ref(fake_gamestate1))
        s1.was_called_with(match.ref(flow), match.ref(fake_gamestate2))
      end)

    end)

    describe('instantiate_and_register_gamestates', function ()

      -- we won't even try calling on_enter, etc. so empty tables are enough
      local fake_gamestate1 = {"gamestate1"}
      local fake_gamestate2 = {"gamestate2"}

      setup(function ()
        stub(gameapp, "register_gamestates")
      end)

      teardown(function ()
        gameapp.register_gamestates:revert()
      end)

      after_each(function ()
        gameapp.register_gamestates:clear()
      end)

      before_each(function ()
        -- quick way to override method
        -- without having to derive a class from gameapp, then instantiate it
        function app:instantiate_gamestates()
          return {fake_gamestate1, fake_gamestate2}
        end
      end)

      it('should add all gamestates returned by instantiate_gamestates to flow', function ()
        app:instantiate_and_register_gamestates()

        local s = assert.spy(gameapp.register_gamestates)
        s.was_called(1)
        s.was_called_with(match.ref(app), {{"gamestate1"}, {"gamestate2"}})
      end)

    end)

    describe('(with mock_manager1 and mock_manager2 registered)', function ()

      before_each(function ()
        -- relies on register_managers being correct
        app:register_managers({mock_manager1, mock_manager2})
      end)

      describe('start', function ()

        setup(function ()
          spy.on(gameapp, "instantiate_and_register_managers")
          spy.on(gameapp, "instantiate_and_register_gamestates")
          spy.on(gameapp, "on_pre_start")
          spy.on(gameapp, "on_post_start")
          stub(flow, "query_gamestate_type")
        end)

        teardown(function ()
          gameapp.instantiate_and_register_managers:revert()
          gameapp.instantiate_and_register_gamestates:revert()
          gameapp.on_pre_start:revert()
          gameapp.on_post_start:revert()
          flow.query_gamestate_type:revert()
        end)

        after_each(function ()
          gameapp.instantiate_and_register_managers:clear()
          gameapp.instantiate_and_register_gamestates:clear()
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

          it('should call instantiate_and_register_managers', function ()
            app:start()

            assert.spy(gameapp.instantiate_and_register_managers).was_called(1)
            assert.spy(gameapp.instantiate_and_register_managers).was_called_with(match.ref(app))
          end)

          it('should call instantiate_and_register_gamestates', function ()
            app:start()

            assert.spy(gameapp.instantiate_and_register_gamestates).was_called(1)
            assert.spy(gameapp.instantiate_and_register_gamestates).was_called_with(match.ref(app))
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
          stub(coroutine_runner, "stop_all_coroutines")
          stub(input, "init")
          stub(flow, "init")
          spy.on(gameapp, "on_reset")
        end)

        teardown(function ()
          coroutine_runner.stop_all_coroutines:revert()
          input.init:revert()
          flow.init:revert()
          gameapp.on_reset:revert()
        end)

        after_each(function ()
          coroutine_runner.stop_all_coroutines:clear()
          input.init:clear()
          flow.init:clear()
          gameapp.on_reset:clear()
        end)

        it('should call coroutine_runner:stop_all_coroutines', function ()
          app:reset()

          assert.spy(coroutine_runner.stop_all_coroutines).was_called(1)
          assert.spy(coroutine_runner.stop_all_coroutines).was_called_with(match.ref(app.coroutine_runner))
        end)

        it('should call input:init', function ()
          app:reset()

          assert.spy(input.init).was_called(1)
          assert.spy(input.init).was_called_with(match.ref(input))
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

        -- #debug_menu only
        it('should immediately return when debug_paused is true', function ()
          app.debug_paused = true

          app:update()

          assert.spy(input.process_players_inputs).was_not_called()
          assert.spy(coroutine_runner.update_coroutines).was_not_called()
          assert.spy(mock_manager1.update).was_not_called()
          assert.spy(mock_manager2.update).was_not_called()
          assert.spy(flow.update).was_not_called()
          assert.spy(app.on_update).was_not_called()
        end)

        it('should call input:process_players_inputs', function ()
          app:update()

          assert.spy(input.process_players_inputs).was_called(1)
          assert.spy(input.process_players_inputs).was_called_with(match.ref(input))
        end)

        it('should update coroutines via coroutine runner', function ()
          app:update()

          assert.spy(coroutine_runner.update_coroutines).was_called(1)
          assert.spy(coroutine_runner.update_coroutines).was_called_with(match.ref(app.coroutine_runner))
        end)

        -- bugfix history:
        -- + forget self. in front of managers
        it('should update all registered managers that are active', function ()
          app:update()

          assert.spy(mock_manager1.update).was_called(1)
          assert.spy(mock_manager1.update).was_called_with(match.ref(mock_manager1))

          assert.spy(mock_manager2.update).was_not_called()
        end)

        it('should update the flow', function ()
          app:update()

          assert.spy(flow.update).was_called(1)
          assert.spy(flow.update).was_called_with(match.ref(flow))
        end)

        it('should call on_update', function ()
          app:update()

          assert.spy(app.on_update).was_called(1)
          assert.spy(app.on_update).was_called_with(match.ref(app))
        end)

      end)

      describe('draw', function ()

        setup(function ()
          stub(_G, "cls")
          stub(flow, "render")
          stub(flow, "render_post")
        end)

        teardown(function ()
          cls:revert()
          flow.render:revert()
          flow.render_post:revert()
        end)

        after_each(function ()
          cls:clear()
          flow.render:clear()
          flow.render_post:clear()

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

        it('should call flow:render_post', function ()
          -- call order: should be after manager render,
          -- but we cannot easily test that
          app:draw()

          local s = assert.spy(flow.render_post)
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

    describe('wait_and_do', function ()
      --todo
    end)

  end)  -- (with default app)

end)
