require("engine/test/bustedhelper")
require("engine/test/unittest_helper")

describe('unittest_helper', function ()

  describe('are_same', function ()
    local single_t = {}

    local comparable_mt_sum = {
      __eq = function (lhs, rhs)
        -- a flexible check that allows different member values
        --  to have the table considered equal in the end
        return lhs.a + lhs.b == rhs.a + rhs.b
      end
    }
    local comparable_mt_offset = {
      __eq = function (lhs, rhs)
        -- a contrived check that makes sure __eq is used by returning true
        --  when it should be false in raw content
        return lhs.a == rhs.a - 1
      end
    }

    local comparable_struct1 = {a = 1, b = 2}
    local comparable_struct2 = {a = 1, b = 2}
    local comparable_struct3 = {a = 2, b = 1}
    local comparable_struct4 = {a = 1}
    local comparable_struct5 = {a = 1}
    local comparable_struct6 = {a = 2}

    setmetatable(comparable_struct1, comparable_mt_sum)
    setmetatable(comparable_struct2, comparable_mt_sum)
    setmetatable(comparable_struct3, comparable_mt_sum)
    setmetatable(comparable_struct4, comparable_mt_offset)
    setmetatable(comparable_struct5, comparable_mt_offset)
    setmetatable(comparable_struct6, comparable_mt_offset)

    -- in real tests you should always use are_same_with_message for maximum info,
    --  but here we really want to test the core are_same
    --  (you can always temporarily use are_same_with_message to debug what's going on,
    --  assuming the latter is correct)

    -- bugfix history:
    -- _ the non-table and comparable_struct tests below have been added, as I was exceptionally covering
    --   the utest files themselves and saw that the metatables were not used at all; so I fixed are_same itself
    --   to check __eq on the metatable instead of the table

    it('return true if both elements are not table, but equal', function ()
      assert.is_true(are_same(2, 2))
    end)
    it('return false if both elements are not table, and not equal', function ()
      assert.is_false(are_same(2, 3))
    end)

    it('return true if both tables define __eq that returns true, and using metatable __eq', function ()
      assert.is_true(are_same(comparable_struct1, comparable_struct2, true))
      assert.is_true(are_same(comparable_struct1, comparable_struct3, true))
      assert.is_true(are_same(comparable_struct4, comparable_struct6, true))
    end)
    it('return false if both tables define __eq that returns false, and using metatable __eq', function ()
      assert.is_false(are_same(comparable_struct4, comparable_struct5, true))
    end)

    it('return false if both tables define __eq that returns true, but comparing different raw content', function ()
      assert.is_false(are_same(comparable_struct1, comparable_struct3))
      assert.is_false(are_same(comparable_struct4, comparable_struct6))
    end)

    it('return true if both tables define __eq that returns false, but comparing same raw content', function ()
      assert.is_true(are_same(comparable_struct4, comparable_struct5))
    end)

    it('return true both tables are empty', function ()
      assert.is_true(are_same({}, {}))
    end)
    it('return true if both tables are sequences with the same elements in order', function ()
      assert.is_true(are_same({false, "ah"}, {false, "ah"}))
    end)
    it('return true if both tables are former sequences with a hole with the same elements in order', function ()
      assert.is_true(are_same({2, nil, "ah"}, {2, nil, "ah"}))
    end)
    it('return true if both tables are sequences with the same elements by ref in order', function ()
      assert.is_true(are_same({2, single_t}, {2, single_t}))
    end)

    it('return true if both tables have the same keys and values', function ()
      assert.is_true(are_same({a = "str", b = "at"}, {b = "at", a = "str"}))
    end)
    it('return true if both tables have the same keys and values by reference', function ()
      assert.is_true(are_same({a = "str", b = single_t, c = nil}, {b = single_t, c = nil, a = "str"}))
    end)
    it('return true if both tables have the same keys and values by custom equality', function ()
      assert.is_true(are_same({a = "str", b = comparable_struct1}, {b = comparable_struct2, a = "str"}))
    end)

    it('return true if both tables have the same keys and values, even if their metatables differ', function ()
      local t1 = {}
      setmetatable(t1, {})
      local t2 = {}
      assert.is_true(are_same(t1, t2))
    end)

    it('return false if both tables are sequences but an element is missing on the first', function ()
      assert.is_false(are_same({1, 2}, {1, 2, 3}))
    end)
    it('return false if both tables are sequences but an element is missing on the second', function ()
      assert.is_false(are_same({1, 2, 3}, {1, 2}))
    end)
    it('return false if both tables are sequences but an element differs', function ()
      assert.is_false(are_same({1, 2, 3}, {1, 2, 4}))
    end)
    it('return true if both tables are sequences with the same elements by value at deep level', function ()
      assert.is_true(are_same({1, 2, {}}, {1, 2, {}}))
    end)

    it('return false if first table has a key the other doesn\'t have', function ()
      assert.is_false(are_same({a = false, b = "at"}, {a = false}))
    end)
    it('return false if second table has a key the other doesn\'t have', function ()
      assert.is_false(are_same({b = "the"}, {c = 54, b = "the"}))
    end)
    it('return false if both tables have the same keys but a value differs', function ()
      assert.is_false(are_same({a = false, b = "at"}, {a = false, b = "the"}))
    end)
    it('return true if both tables have the same keys and values by value', function ()
      assert.is_true(are_same({a = "str", t = {}}, {a = "str", t = {}}))
    end)
    it('return false if both tables have the same values but a key differs by reference', function ()
      assert.is_false(are_same({[{20}] = 10}, {[{20}] = 10}))
    end)

    it('return true if both tables have the same key refs and value contents by defined equality', function ()
      assert.is_true(are_same({a = "str", t = {e = vector(5, 8)}}, {a = "str", t = {e = vector(5, 8)}}, true))
    end)
    it('return false if we compare with metatable __eq and some values have the same content but differ by type', function ()
      assert.is_false(are_same({x = 5, y = 8}, vector(5, 8), true))
    end)
    it('return false if we compare with metatable __eq and some values have the same content but differ by type (deep)', function ()
      assert.is_false(are_same({a = "str", t = {e = {x = 5, y = 8}}}, {a = "str", t = {e = vector(5, 8)}}, true))
    end)
    it('return true if we compare raw content and some values have the same content, even if they differ by type (deep)', function ()
      assert.is_true(are_same({{x = 1, y = 2}, t = {e = {x = 5, y = 8}}}, {vector(1, 2), t = {e = vector(5, 8)}}))
    end)
    it('return false if we compare raw content and some values have the same content, but they differ by type at a deep level', function ()
      assert.is_false(are_same({{x = 1, y = 2}, t = {e = {x = 5, y = 8}}}, {vector(1, 2), t = {e = vector(5, 8)}}, false, true))
    end)
    it('return true if we compare raw content and some values have the same content, even they differ by type at root AND deeper level', function ()
      assert.is_true(are_same(vector({e = {x = 5, y = 8}}, 14), {x = {e = vector(5, 8)}, y = 14}))
    end)
    it('return false if we compare raw content and some values have the same content, but they differ by type at a deep level', function ()
      assert.is_false(are_same(vector({e = {x = 5, y = 8}}, 14), {x = {e = vector(5, 8)}, y = 14}, false, true))
    end)
  end)

  describe('are_same_with_message', function ()
    it('should return (true, "Expected...") when the values are the same', function ()
      local expected_message = "Expected objects to not be the same (use_mt_equality: false, use_mt_equality_from_2nd_level: false).\nPassed in:\n{[1] = 1, [2] = 2, [3] = 3}\nDid not expect:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({true, expected_message}, {are_same_with_message({1, 2, 3}, {1, 2, 3})})
    end)
    it('should return (false, "Expected...") when the values are not the same', function ()
      local expected_message = "Expected objects to be the same (use_mt_equality: false, use_mt_equality_from_2nd_level: true).\nPassed in:\n{[1] = 1, [2] = 3, [3] = 2}\nExpected:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({false, expected_message}, {are_same_with_message({1, 2, 3}, {1, 3, 2}, false, true)})
    end)
    it('should return (true, "Expected...") when the values are the same', function ()
      local expected_message = "Expected objects to not be the same (use_mt_equality: true, use_mt_equality_from_2nd_level: false).\nPassed in:\n{[1] = 1, [2] = 2, [3] = 3}\nDid not expect:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({true, expected_message}, {are_same_with_message({1, 2, 3}, {1, 2, 3}, true)})
    end)
    it('should return (false, "Expected...") when the values are not the same', function ()
      local expected_message = "Expected objects to be the same (use_mt_equality: true, use_mt_equality_from_2nd_level: true).\nPassed in:\n{[1] = 1, [2] = 3, [3] = 2}\nExpected:\n{[1] = 1, [2] = 2, [3] = 3}"
      assert.are_same({false, expected_message}, {are_same_with_message({1, 2, 3}, {1, 3, 2}, true, true)})
    end)
  end)

end)
