require("engine/test/bustedhelper")
local manager = require("engine/application/manager")

describe('manager', function ()

  describe('(dummy derived manager)', function ()

    local dummy_manager = derived_class(manager)

    function dummy_manager:_init()
      manager._init(self)
    end

    local dummy_manager2 = derived_class(manager)

    function dummy_manager2:_init()
      manager._init(self, false)  -- start inactive
    end

    local mgr

    before_each(function ()
      mgr = dummy_manager()
    end)

    it('if not defined on subclass, static member type should be ":undefined"', function ()
      assert.are_equal(':undefined', mgr.type)
    end)

    it('_init should not set the app yet', function ()
      assert.is_nil(mgr.app)
    end)

    it('_init should set active to true by default', function ()
      assert.is_true(mgr.active)
    end)

    it('_init should set active to passed ', function ()
      local inactive_mgr = dummy_manager2()
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
