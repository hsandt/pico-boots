require("engine/test/bustedhelper")
require("engine/core/table_helper")

describe('merge', function ()

  it('should merge content of t2 into t1', function ()
    local t1 = {a = 1, b = 2}
    local t2 = {c = 3}
    merge(t1, t2)
    assert.are_same({a = 1, b = 2, c = 3}, t1)
  end)

  it('should overwrite content of t2 having same key as entry in t1', function ()
    local t1 = {a = 1, b = 2}
    local t2 = {b = 3}
    merge(t1, t2)
    assert.are_same({a = 1, b = 3}, t1)
  end)

end)
