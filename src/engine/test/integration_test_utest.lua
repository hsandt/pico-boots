require("engine/test/bustedhelper")
local integration_test = require("engine/test/integration_test")

local gameapp = require("engine/application/gameapp")
local time_trigger = require("engine/test/time_trigger")

describe('integration_test', function ()

  local mock_app = gameapp(60)

  describe('init', function ()

    it('should create an integration test with a name (and active gamestates for non-pico8 build)', function ()
      local test = integration_test('character follows ground', {':stage'})
      assert.is_not_nil(test)
      assert.are_same({'character follows ground', nil, {}, nil, 0, {':stage'}},
        {test.name, test.setup, test.action_sequence, test.final_assertion, test.timeout_frames, test.active_gamestates})
    end)

    it('should assert if active gamestates is nil for non-pico8 build', function ()
      assert.has_error(function ()
        integration_test('missing active gamestates')
        end,
        "integration_test.init: non-pico8 build requires active_gamestates to define them at runtime")
    end)

  end)

  describe('_tostring', function ()
    it('should return "integration_test \'{self.name}\'', function ()
      local test = integration_test('character follows ground', function () end)
      assert.are_equal("[integration_test 'character follows ground']", test:_tostring())
    end)
  end)

  describe('add_action', function ()
    it('should add a scripted action in the action sequence', function ()
      local test = integration_test('character follows ground', function () end)
      action_callback = function () end
      test:add_action(time_trigger(1.0, false, 60), action_callback, 'my_action')
      assert.are_equal(1, #test.action_sequence)
      assert.are_same({time_trigger(1.0, false, 60), action_callback, 'my_action'}, {test.action_sequence[1].trigger, test.action_sequence[1].callback, test.action_sequence[1].name})
    end)
  end)

  describe('set_timeout', function ()
    it('should set the timeout in frames', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(120)
      assert.are_equal(120, test.timeout_frames)
    end)
  end)

  describe('check_timeout', function ()

    it('should return false if timeout is 0', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(0)
      assert.is_false(test:check_timeout(50))
    end)

    it('should return false if frame is less than timeout (119 < 120)', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(120)
      assert.is_false(test:check_timeout(119))
    end)

    it('should return true if frame is greater than or equal to timeout', function ()
      local test = integration_test('character follows ground', function () end)
      test:set_timeout(120)
      assert.is_true(test:check_timeout(120))
    end)

  end)

  describe('check_final_assertion', function ()
    it('should call the final assertion with app and return the result', function ()
      local test = integration_test('character follows ground', function () end)
      test.final_assertion = function(app)
        return false, 'error message for app fps: '..app.fps
      end
      assert.are_same({false, 'error message for app fps: 60'}, {test:check_final_assertion(mock_app)})
    end)
  end)

end)
