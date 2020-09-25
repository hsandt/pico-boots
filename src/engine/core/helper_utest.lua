require("engine/test/bustedhelper")
require("engine/core/helper")  -- already in engine/common, but added for clarity

describe('transform', function ()

  it('should return a sequence where a callback was applied to each element', function ()
    local function square(x)
      return x * x
    end

    assert.are_same({1, 4, 9}, transform({1, -2, 3}, square))
  end)

  it('should return a table where a callback was applied to each value', function ()
    local function square(x)
      return x * x
    end

    assert.are_same({1, hello = 4, 9}, transform({1, hello = -2, 3}, square))
  end)
end)

describe('contains', function ()
  it('should return true when the searched value is contained in the table (simple sequence)', function ()
    assert.is_true(contains({1, 2, 3}, 2))
  end)
  it('should return true when the searched value is contained in the table (complex table)', function ()
    assert.is_true(contains({a = 1, b = 2, [3] = "c"}, 2))
  end)
  it('should return true when the searched value is contained in the table (custom equality)', function ()
    assert.is_true(contains({"string", vector(2, 4)}, vector(2, 4)))
  end)
  it('should return false when the searched value is not contained in the table (simple sequence)', function ()
    assert.is_false(contains({1, 2, 3}, 0))
  end)
  it('should return false when the searched value is not contained in the table (complex table)', function ()
    assert.is_false(contains({a = 1, b = 2, [3] = "c"}, 3))
  end)
  it('should return false when the searched value is not contained in the table (custom equality)', function ()
    assert.is_false(contains({"string", vector(2, 5)}, vector(2, 4)))
  end)
end)

describe('is_empty', function ()
  it('return true if the table is empty', function ()
    assert.is_true(is_empty({}))
  end)
  it('return false if the sequence is not empty', function ()
    assert.is_false(is_empty({2, "ah"}))
  end)
  it('return false if the table has only non-sequence entries', function ()
    assert.is_false(is_empty({a = "str"}))
  end)
  it('return false if the table has a mix of entries', function ()
    assert.is_false(is_empty({4, 5, d = "dummy"}))
  end)
end)

describe('clear_table', function ()
  it('should clear a sequence', function ()
    local t = {1, 5, -5}
    clear_table(t)
    assert.are_equal(0, #t)
  end)
  it('should clear a table', function ()
    local t = {1, 5, a = "b", b = 50.1}
    clear_table(t)
    assert.is_true(is_empty(t))
  end)
end)

describe('unpack', function ()
  it('should unpack a sequence fully by default', function ()
    local function foo(a, b, c)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
    end
    foo(unpack({1, "foo", 20.2}))
  end)
  it('should unpack a sequence from start if from is not passed', function ()
    local function foo(a, b, c, d)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
      assert.are_not_equal(50, d)
    end
    foo(unpack({1, "foo", 20.2, 50}, nil, 3))
  end)
  it('should unpack a sequence to the end if to is not passed', function ()
    local function foo(a, b, c)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
    end
    foo(unpack({45, 1, "foo", 20.2}, 2))
  end)
  it('should unpack a sequence from from to to', function ()
    local function foo(a, b, c, d)
      assert.are_same({1, "foo", 20.2}, {a, b, c})
      assert.are_not_equal(50, d)
    end
    foo(unpack({45, 1, "foo", 20.2, 50}, 2, 4))
  end)
end)

describe('invert_table', function ()
  it('should return a table with reversed keys and values', function ()
    assert.are_same({[41] = "a", foo = 1}, invert_table({a = 41, [1] = "foo"}))
  end)
end)

describe('yield_delay (wrapped in set_var_after_delay_async)', function ()
  local test_var
  local coroutine

  local function set_var_after_delay_async(nb_frames)
    yield_delay(nb_frames)
    test_var = 1
  end

  before_each(function ()
    test_var = 0
    coroutine = cocreate(set_var_after_delay_async)
  end)

  it('should start suspended', function ()
    assert.are_equal("suspended", costatus(coroutine))
    assert.are_equal(0, test_var)
  end)

  it('should not stop after 59/60 frames', function ()
    coresume(coroutine, 60)  -- pass delay of 60 frames in 1st call
    for t = 2, 59 do
      coresume(coroutine)  -- further calls don't need arg, it's only used as yield() return value
    end
    assert.are_equal("suspended", costatus(coroutine))
    assert.are_equal(0, test_var)
  end)
  it('should stop after 60/60 frames, and continue body execution', function ()
    coresume(coroutine, 60)
    for t = 2, 60 do
      coresume(coroutine)
    end
    assert.are_equal("dead", costatus(coroutine))
    assert.are_equal(1, test_var)
  end)

end)
