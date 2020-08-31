require("engine/test/bustedhelper")
require("engine/core/fun_helper")

describe('unpacking', function ()
  it('should return a function similar to the decorated function, but receiving a sequence of arguments', function ()
    local function f(a, b, c)
      return a * b + c
    end

    local unpacking_f = unpacking(f)
    assert.are_equal(5, unpacking_f({1, 2, 3}))
  end)
end)
