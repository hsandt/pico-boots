require("engine/test/bustedhelper")
require("engine/core/vector_ext_mirror")

describe('mirrored_x', function ()
  it('(1 3).mirrored_x() => (-1, 3)', function ()
    assert.are_same(vector(1, 3), vector(-1, 3):mirrored_x())
  end)
end)

describe('mirror_x', function ()
  it('(1 -3).mirror_x() => (-1, -3)', function ()
    local v = vector(1, -3)
    v:mirror_x()
    assert.are_same(vector(-1, -3), v)
  end)
end)

describe('mirrored_y', function ()
  it('(1 3).mirrored_y() => (1, -3)', function ()
    assert.are_same(vector(1, 3), vector(1, -3):mirrored_y())
  end)
end)

describe('mirror_y', function ()
  it('(1 -3).mirror_y() => (1, 3)', function ()
    local v = vector(1, -3)
    v:mirror_y()
    assert.are_same(vector(1, 3), v)
  end)
end)
