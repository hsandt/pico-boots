require("engine/test/bustedhelper")
require("engine/core/seq_helper")

describe('seq_contains', function ()
  it('should return true when the searched value is contained in the table', function ()
    assert.is_true(seq_contains({1, 2, 3}, 2))
  end)
  it('should return false when the searched value is not contained in the table', function ()
    assert.is_false(seq_contains({1, 2, 3}, 0))
  end)
  it('should return true when the searched value is contained in the table (custom equality)', function ()
    assert.is_true(seq_contains({"string", vector(2, 4)}, vector(2, 4)))
  end)
  it('should return false when the searched value is not contained in the table (custom equality)', function ()
    assert.is_false(seq_contains({"string", vector(2, 5)}, vector(2, 4)))
  end)
end)

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
