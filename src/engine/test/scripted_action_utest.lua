require("engine/test/bustedhelper")
local scripted_action = require("engine/test/scripted_action")

local time_trigger = require("engine/test/time_trigger")

describe('scripted_action', function ()

  describe('init', function ()
    it('should create a scripted action with a trigger and callback (unnamed)', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2.0, false, 60), do_something)
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2.0, false, 60), do_something, "unnamed"}, {act.trigger, act.callback, act.name})
    end)
    it('should create a scripted action with a trigger, callback and name', function ()
      local do_something = function () end
      local act = scripted_action(time_trigger(2.0, false, 60), do_something, "do_something")
      assert.is_not_nil(act)
      assert.are_same({time_trigger(2.0, false, 60), do_something, "do_something"}, {act.trigger, act.callback, act.name})
    end)
  end)

  describe('_tostring', function ()
    it('should return "scripted_action \'unnamed\' @ {self.trigger}"" if no name', function ()
      local act = scripted_action(time_trigger(2.0, false, 60), function () end)
      assert.are_equal("[scripted_action 'unnamed' @ time_trigger(120)]", act:_tostring())
    end)
    it('should return "scripted_action \'{self.name}\' @ {self.trigger}" if some name', function ()
      local act = scripted_action(time_trigger(2.0, false, 60), function () end, 'do_something')
      assert.are_equal("[scripted_action 'do_something' @ time_trigger(120)]", act:_tostring())
    end)
  end)
end)
