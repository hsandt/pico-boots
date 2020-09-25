require("engine/test/bustedhelper")
require("engine/core/coroutine")

describe('coroutine_curry', function ()

  local function test_fun_async_with_args(var1, var2)
  end

  describe('init', function ()
    it('should initialize a coroutine curry with some arguments', function ()
      local tab = {}
      local curry = coroutine_curry(cocreate(test_fun_async_with_args), 5, tab)
      assert.are_equal(2, #curry.args)
      assert.are_equal(5, curry.args[1])
      assert.are_equal(tab, curry.args[2])
    end)
  end)

  describe('_tostring', function ()
    it('should return "[coroutine_curry] (status) (arg1 arg2 ...)"', function ()
      local my_couroutine_curry = coroutine_curry(cocreate(test_fun_async_with_args), 5, {"hello"})
      assert.are_equal("[coroutine_curry] (suspended) (5, {[1] = \"hello\"})", my_couroutine_curry:_tostring())
      coresume(my_couroutine_curry.coroutine)
      assert.are_equal("[coroutine_curry] (dead) (5, {[1] = \"hello\"})", my_couroutine_curry:_tostring())
    end)
  end)

end)
