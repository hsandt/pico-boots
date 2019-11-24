require("engine/test/bustedhelper")
local manager = require("engine/application/manager")

describe('manager', function ()

  describe('(dummy derived manager)', function ()

    local dummy_manager = new_class(manager)

    local dummy_manager2 = new_class(manager)
    dummy_manager2.initially_active = false

    local mgr
    local mgr2

    before_each(function ()
      mgr = dummy_manager()
      mgr2 = dummy_manager2()
    end)

    it('if not defined on subclass, static member type should be ":undefined"', function ()
      assert.are_equal(':undefined', mgr.type)
    end)

    it('if defined on subclass, static member initially_active should be "true"', function ()
      assert.is_true(mgr.initially_active)
    end)

    it('_init should not set the app yet', function ()
      assert.is_nil(mgr.app)
    end)

    it('_init should set active to initially_active (true)', function ()
      assert.is_true(mgr.active)
    end)

    it('_init should set active to initially_active (false)', function ()
      assert.is_false(mgr2.active)
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
