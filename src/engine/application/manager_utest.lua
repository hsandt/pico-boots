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

    local dummy_manager2 = derived_class(manager)

    function dummy_manager2:_init(app)
      manager._init(self, app, false)  -- start inactive
    end

    local mgr

    before_each(function ()
      mgr = dummy_manager(dummy_app)
    end)

    it('if not defined on subclass, static member type should be ":undefined"', function ()
      assert.are_equal(':undefined', mgr.type)
    end)

    it('_init should inject the app', function ()
      assert.are_equal(dummy_app, mgr.app)
    end)

    it('_init should set active to true by default', function ()
      assert.is_true(mgr.active)
    end)

    it('_init should set active to passed ', function ()
      local inactive_mgr = dummy_manager2(dummy_app)
      assert.is_false(inactive_mgr.active)
    end)

    it('start should do nothing', function ()
      assert.has_no_errors(function ()
        mgr:start()
      end)
    end)

    it('update should do nothing', function ()
      assert.has_no_errors(function ()
        mgr:update()
      end)
    end)

    it('render should do nothing', function ()
      assert.has_no_errors(function ()
        mgr:render()
      end)
    end)

  end)

end)
