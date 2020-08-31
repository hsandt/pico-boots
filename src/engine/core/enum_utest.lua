require("engine/test/bustedhelper")
require("engine/core/enum")

describe('enum', function ()
  it('should return a table containing enum variants with the names passed as a sequence, values starting from 1', function ()
    assert.are_same({
        left = 1,
        right = 2,
        up = 3,
        down = 4
      }, enum {"left", "right", "up", "down"})
  end)
end)
