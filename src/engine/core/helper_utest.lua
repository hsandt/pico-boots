require("engine/test/bustedhelper")
require("engine/core/helper")  -- already in engine/common, but added for clarity

local logging = require("engine/debug/logging")  -- just to get nice_dump

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

describe('unpacking', function ()
  it('should return a function similar to the decorated function, but receiving a sequence of arguments', function ()
    local function f(a, b, c)
      return a * b + c
    end

    local unpacking_f = unpacking(f)
    assert.are_equal(5, unpacking_f({1, 2, 3}))
  end)
end)

describe('contains', function ()
  it('should return true when the searched value is contained in the table', function ()
    assert.is_true(contains({1, 2, 3}, 2))
    assert.is_true(contains({"string", vector(2, 4)}, vector(2, 4)))
  end)
  it('should return false when the searched value is not contained in the table', function ()
    assert.is_false(contains({1, 2, 3}, 0))
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

describe('are_same_shallow', function ()
  local single_t = {}

  local comparable_mt_sum = {
    __eq = function (lhs, rhs)
      -- a flexible check that allows different member values
      --  to have the table considered equal via custom equality
      -- (but to show that are_same_shallow is *not* using it)
      return lhs.a + lhs.b == rhs.a + rhs.b
    end
  }
  local comparable_mt_offset = {
    __eq = function (lhs, rhs)
      -- a contrived check that makes sure __eq is used by returning true
      --  when it should be false in raw content
      -- (but to show that are_same_shallow is *not* using it)
      return lhs.a == rhs.a - 1
    end
  }

  -- hole at 2 is because we copied values from are_same utests
  local comparable_struct1 = {a = 1, b = 2}
  local comparable_struct3 = {a = 2, b = 1}
  local comparable_struct4 = {a = 1}
  local comparable_struct5 = {a = 1}
  local comparable_struct6 = {a = 2}

  setmetatable(comparable_struct1, comparable_mt_sum)
  setmetatable(comparable_struct3, comparable_mt_sum)
  setmetatable(comparable_struct4, comparable_mt_offset)
  setmetatable(comparable_struct5, comparable_mt_offset)
  setmetatable(comparable_struct6, comparable_mt_offset)

  it('return false if both tables define __eq that returns true, but comparing different raw content', function ()
    assert.is_false(are_same_shallow(comparable_struct1, comparable_struct3))
    assert.is_false(are_same_shallow(comparable_struct4, comparable_struct6))
  end)
  it('return true if both tables define __eq that returns false, but comparing same raw content', function ()
    assert.is_true(are_same_shallow(comparable_struct4, comparable_struct5))
  end)

  it('return true both tables are empty', function ()
    assert.is_true(are_same_shallow({}, {}))
  end)

  it('return true if both tables are sequences with the same elements in order', function ()
    assert.is_true(are_same_shallow({false, 3, "ah"}, {false, 3, "ah"}))
  end)
  it('return true if both tables are former sequences with a hole with the same elements in order', function ()
    assert.is_true(are_same_shallow({2, nil, "ah"}, {2, nil, "ah"}))
  end)
  it('return true if both tables are sequences with the same elements by ref in order', function ()
    assert.is_true(are_same_shallow({2, single_t}, {2, single_t}))
  end)

  it('return true if both tables have the same keys and values', function ()
    assert.is_true(are_same_shallow({a = 45, b = "at"}, {b = "at", a = 45}))
  end)
  it('return true if both tables have the same keys and values by reference', function ()
    assert.is_true(are_same_shallow({a = "str", b = single_t, c = nil}, {b = single_t, c = nil, a = "str"}))
  end)
  it('return true if both tables have the same keys and values by custom equality', function ()
    assert.is_true(are_same_shallow({a = "str", b = comparable_struct1}, {b = comparable_struct3, a = "str"}))
  end)

  it('return true if both tables have the same keys and values, even if their metatables differ', function ()
    local t1 = {}
    setmetatable(t1, {})
    local t2 = {}
    assert.is_true(are_same_shallow(t1, t2))
  end)

  it('return false if both tables are sequences but an element is missing on the first', function ()
    assert.is_false(are_same_shallow({1, 2}, {1, 2, 3}))
  end)
  it('return false if both tables are sequences but an element is missing on the second', function ()
    assert.is_false(are_same_shallow({1, 2, 3}, {1, 2}))
  end)
  it('return false if both tables are sequences but an element differs', function ()
    assert.is_false(are_same_shallow({1, 2, 3}, {1, 2, 4}))
  end)
  it('return false if both tables are sequences with the same elements by value at deep level', function ()
    assert.is_false(are_same_shallow({1, 2, {}}, {1, 2, {}}))
  end)

  it('return false if first table has a key the other doesn\'t have', function ()
    assert.is_false(are_same_shallow({a = false, b = "at"}, {a = false}))
  end)
  it('return false if second table has a key the other doesn\'t have', function ()
    assert.is_false(are_same_shallow({b = "the"}, {c = 54, b = "the"}))
  end)
  it('return false if both tables have the same keys but a value differs', function ()
    assert.is_false(are_same_shallow({a = false, b = "at"}, {a = false, b = "the"}))
  end)
  it('return false if both tables have the same keys and values by value but not by ref (table member)', function ()
    assert.is_false(are_same_shallow({a = "str", t = {}}, {a = "str", t = {}}))
  end)
  it('return false if both tables have the same values but a key differs by reference', function ()
    assert.is_false(are_same_shallow({[{20}] = 10}, {[{20}] = 10}))
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
