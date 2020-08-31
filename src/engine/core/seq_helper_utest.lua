require("engine/test/bustedhelper")
require("engine/core/seq_helper")

describe('copy', function ()
  it('should return a copy of a sequence', function ()
    local seq = {0, 1, -2, 3}
    local copied_seq = copy_seq(seq)
    assert.are_not_equal(seq, copied_seq)
    assert.are_same(seq, copied_seq)
  end)
end)

describe('filter', function ()
  it('should return a sequence where only elements verifying the condition function have been kept', function ()
    local function is_even(x)
      return x % 2 == 0
    end

    assert.are_same({0, -2}, filter({0, 1, -2, 3}, is_even))
  end)
end)
