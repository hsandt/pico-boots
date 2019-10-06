require("engine/test/bustedhelper")
local gamestate = require("engine/application/gamestate")

describe('gamestate', function ()

  describe('(dummy derived gamestate)', function ()

    -- as long as there are no type/attribute checks in _init, we don't need
    --  to actualy derive from gameapp for the dummy app
    local dummy_app = {}
    local dummy_gamestate = derived_class(gamestate)

    function dummy_gamestate:_init(app)
      gamestate._init(self, app)
    end

    local state

    before_each(function ()
      state = dummy_gamestate(dummy_app)
    end)

    it('if not defined on subclass, static member type should be ":undefined"', function ()
      assert.are_equal(':undefined', state.type)
    end)

    it('_init should inject the app', function ()
      assert.are_equal(dummy_app, state.app)
    end)

    it('on_enter should do nothing', function ()
      assert.has_no_errors(function ()
        state:on_enter()
      end)
    end)

    it('on_exit should do nothing', function ()
      assert.has_no_errors(function ()
        state:on_exit()
      end)
    end)

    it('update should do nothing', function ()
      assert.has_no_errors(function ()
        state:update()
      end)
    end)

    it('render should do nothing', function ()
      assert.has_no_errors(function ()
        state:render()
      end)
    end)

  end)

end)
