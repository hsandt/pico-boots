require("engine/test/bustedhelper")
local manager = require("engine/application/manager")

describe('manager', function ()

  describe('(dummy derived manager)', function ()

    -- as long as there are no type/attribute checks in _init, we don't need
    --  to actualy derive from gameapp for the dummy app
    local dummy_app = {}
    local dummy_manager = derived_class(manager)

    function dummy_manager:_init(app)
      manager._init(self, app)
    end

    local state

    before_each(function ()
      state = dummy_manager(dummy_app)
    end)

    it('if not defined on subclass, static member type should be ":undefined"', function ()
      assert.are_equal(':undefined', state.type)
    end)

    it('_init should inject the app', function ()
      assert.are_equal(dummy_app, state.app)
    end)

    it('_init should set active to true', function ()
      assert.is_true(state.active)
    end)

    it('start should do nothing', function ()
      assert.has_no_errors(function ()
        state:start()
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
