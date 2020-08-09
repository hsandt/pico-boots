require("engine/test/bustedhelper")
require("engine/core/helper")  -- already in engine/common, but added for clarity

local logging = require("engine/debug/logging")  -- just to get nice_dump

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

describe('are_same', function ()
  local single_t = {}

  local comparable_mt_sum = {
    __eq = function (lhs, rhs)
      -- a flexible check that allows different member values to have the table considered equal in the end
      return lhs.a + lhs.b == rhs.a + rhs.b
    end
  }
  local comparable_mt_offset = {
    __eq = function (lhs, rhs)
      -- a contrived check that makes sure __eq is used by returning true when it should be false in raw content
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

  it('return true if both tables define __eq that returns true, and not comparing raw content', function ()
    assert.is_true(are_same(comparable_struct1, comparable_struct2))
    assert.is_true(are_same(comparable_struct1, comparable_struct3))
    assert.is_true(are_same(comparable_struct4, comparable_struct6))
  end)
  it('return true if both tables define __eq that returns false, and not comparing raw content', function ()
    assert.is_false(are_same(comparable_struct4, comparable_struct5))
  end)

  it('return false if both tables define __eq that returns true, but comparing different raw content', function ()
    assert.is_false(are_same(comparable_struct1, comparable_struct3, true))
    assert.is_false(are_same(comparable_struct4, comparable_struct6, true))
  end)

  it('return true if both tables define __eq that returns false, but comparing same raw content', function ()
    assert.is_true(are_same(comparable_struct4, comparable_struct5, true))
  end)

  it('return true both tables are empty', function ()
    assert.is_true(are_same({}, {}))
  end)
  it('return true if both tables are sequences with the same elements in order', function ()
    assert.is_true(are_same({false, "ah"}, {false, "ah"}))
  end)
  it('return true if both tables are sequences with the same elements by ref in order', function ()
    assert.is_true(are_same({2, single_t}, {2, single_t}))
  end)
  it('return true if both tables are former sequences with a hole with the same elements in order', function ()
    assert.is_true(are_same({2, nil, "ah"}, {2, nil, "ah"}))
  end)
  it('return true if both tables have the same keys and values', function ()
    assert.is_true(are_same({a = "str", b = "at"}, {b = "at", a = "str"}))
  end)
  it('return true if both tables have the same keys and values by reference', function ()
    assert.is_true(are_same({a = "str", b = single_t, c = nil}, {b = single_t, c = nil, a = "str"}))
  end)
  it('return true if both tables have the same keys and values', function ()
    assert.is_true(are_same({a = false, b = "at"}, {b = "at", a = false}))
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
  it('return false if both tables are sequences with the same elements by value at deep level', function ()
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
  it('return false if we don\'t compare_raw_content and some values have the same content but differ by type', function ()
    assert.is_false(are_same({x = 5, y = 8}, vector(5, 8)))
  end)
  it('return false if we don\'t compare_raw_content and some values have the same content but differ by type (deep)', function ()
    assert.is_false(are_same({a = "str", t = {e = {x = 5, y = 8}}}, {a = "str", t = {e = vector(5, 8)}}))
  end)
  it('return true if we compare_raw_content and some values have the same content, even if they differ by type (deep)', function ()
    assert.is_true(are_same({x = 5, y = 8}, vector(5, 8), true))
  end)
  it('return true if we compare_raw_content and some values have the same content, even if they differ by type (deep)', function ()
    assert.is_true(are_same({{x = 1, y = 2}, t = {e = {x = 5, y = 8}}}, {vector(1, 2), t = {e = vector(5, 8)}}, true))
  end)
  it('return false if we compare_raw_content and some values have the same content, but they differ by type at a deep level', function ()
    assert.is_false(are_same({{x = 1, y = 2}, t = {e = {x = 5, y = 8}}}, {vector(1, 2), t = {e = vector(5, 8)}}, true, true))
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

describe('to_big', function ()
  it('"abc" => "abc"', function ()
    assert.are_equal("abc", to_big("abc"))
  end)
  it('"\65bc" => "abc"', function ()
    assert.are_equal("abc", to_big("\65bc"))
  end)
  it('"XYZ" => "xyz"', function ()
    assert.are_equal("xyz", to_big("XYZ"))
  end)
end)

describe('string_tonum', function ()
  it('"100" => 100', function ()
    assert.are_equal(100, string_tonum("100"))
  end)
  -- unlike tonum, this one works for both pico8 and native Lua
  it('"-25.25" => -25.25', function ()
    assert.are_equal(-25.25, string_tonum("-25.25"))
  end)
  it('"304.25" => 304.25', function ()
    assert.are_equal(304.25, string_tonum(304.25))
  end)
  it('"-25.25" => -25.25', function ()
    assert.are_equal(-25.25, string_tonum(-25.25))
  end)
  it('"0x0000.2fa4" => 0x0000.2fa4', function ()
    assert.are_equal(0x0000.2fa4, string_tonum("0x0000.2fa4"))
  end)
  it('"-0x0000.2fa4" => -0x0000.2fa4', function ()
    assert.are_equal(-0x0000.2fa4, string_tonum("-0x0000.2fa4"))
  end)
  it('"-abc" => error (minus sign instead of hyphen-minus)', function ()
    assert.has_error(function ()
      string_tonum("-abc")
    end,
    "could not parse absolute part of number: '-abc'")
  end)
  it('"−5" => error (minus sign instead of hyphen-minus)', function ()
    assert.has_error(function ()
      string_tonum("−5")
    end,
    "could not parse number: '−5'")
  end)
  it('"abc" => error (minus sign instead of hyphen-minus)', function ()
    assert.has_error(function ()
      string_tonum("abc")
    end,
    "could not parse number: 'abc'")
  end)
  it('nil => error', function ()
    assert.has_error(function ()
      string_tonum(nil)
    end,
    "bad argument #1 to 'sub' (string expected, got nil)")
  end)
  it('true => error', function ()
    assert.has_error(function ()
      string_tonum(true)
    end,
    "bad argument #1 to 'sub' (string expected, got boolean)")
  end)
  it('{} => error', function ()
    assert.has_error(function ()
      string_tonum({})
    end,
    "bad argument #1 to 'sub' (string expected, got table)")
  end)
end)

describe('stringify', function ()
  it('nil => "[nil]"', function ()
    assert.are_equal("[nil]", stringify(nil))
  end)
  it('"string" => "string"', function ()
    assert.are_equal("string", stringify("string"))
  end)
  it('true => "true"', function ()
    assert.are_equal("true", stringify(true))
  end)
  it('false => "false"', function ()
    assert.are_equal("false", stringify(false))
  end)
  it('56 => "56"', function ()
    assert.are_equal("56", stringify(56))
  end)
  it('56.2 => "56.2"', function ()
    assert.are_equal("56.2", stringify(56.2))
  end)
  it('vector(2 3) => "vector(2 3)" (_tostring implemented)', function ()
    assert.are_equal("vector(2, 3)", stringify(vector(2, 3)))
  end)
  it('{} => "[table]" (_tostring not implemented)', function ()
    assert.are_equal("[table]", stringify({}))
  end)
  it('function => "[function]"', function ()
    local f = function ()
    end
    assert.are_equal("[function]", stringify(f))
  end)
end)

describe('orderedPairs', function ()
  it('{f = 4, ["0"] = "a", b = -100} => {"0", "a"}, {"b", -100}, {"f", 4}', function ()
    -- we cannot test an iterator directly, but we can build something
    --   that demonstrates that iteration is done in order (alphabetical here)
    local result = {}
    for key, value in orderedPairs({f = 4, ["0"] = "a", b = -100}) do
      add(result, {key, value})
    end
    assert.are_same({{"0", "a"}, {"b", -100}, {"f", 4}}, result)
  end)
end)

describe('dump', function ()

  -- basic types

  it('nil => "[nil]"', function ()
    assert.are_equal("[nil]", dump(nil))
  end)
  it('"string" => ""string""', function ()
    assert.are_equal("\"string\"", dump("string"))
  end)
  it('true => "true"', function ()
    assert.are_equal("true", dump(true))
  end)
  it('false => "false"', function ()
    assert.are_equal("false", dump(false))
  end)
  it('56 => "56"', function ()
    assert.are_equal("56", dump(56))
  end)
  it('56.2 => "56.2"', function ()
    assert.are_equal("56.2", dump(56.2))
  end)

  -- as_key: used to mimic key representation in lua tables

  it('"string" => "string"', function ()
    assert.are_equal("string", dump("string", true))
  end)
  it('true => "[true]"', function ()
    assert.are_equal("[true]", dump(true, true))
  end)
  it('56.2 => "[56.2]"', function ()
    assert.are_equal("[56.2]", dump(56.2, true))
  end)

  -- sequence of mixed values

  it('{1 nil "string"} => "{[1] = 1 [3] = "string"}"', function ()
    assert.are_equal("{[1] = 1, [3] = \"string\"}", dump({1, nil, "string"}))
  end)

  -- mix of non-comparable keys (cannot use sorted_keys here)

  it('{[7] = 5 string = "other"} => "{[7] = 5, string = "other"}" or "{string = "other", [7] = 5}"', function ()
    -- matchers are difficult to use outside of called_with, so we can't use match.any_of directly
    -- instead we test the alternative with a simple assert.is_true and a custom message to debug if false
    assert.is_true(contains_with_message({"{[7] = 5, string = \"other\"}", "{string = \"other\", [7] = 5}"},
      dump({[7] = 5, string = "other"})))
  end)

  -- mix of sequence of and indexed values

  it('{5 "text" string = "other"} => "{[1] = 5 [2] = "text" string = "other"}', function ()
    assert.are_equal("{[1] = 5, [2] = \"text\", string = \"other\"}", dump({5, "text", string = "other"}))
  end)

  it('{...} => "{[1] = 2 mytable = {[1] = 1 [2] = 3 key = "value"}}', function ()
    assert.are_equal("{[1] = 2, mytable = {[1] = 1, [2] = 3, key = \"value\"}}", dump({2, mytable = {1, 3, key = "value"}}))
  end)

  -- tables as values

  it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = 11}', function ()
    assert.are_equal("{[{[1] = 1, [2] = 3, key = \"value\"}] = 11}", dump({[{1, 3, key = "value"}] = 11}))
  end)

  it('{...} => "{{[1] = 1 [2] = 3 key = "value"} = {[1] = true [2] = false}}', function ()
    assert.are_equal("{[{[1] = 1, [2] = 3, key = \"value\"}] = {[1] = true, [2] = false}}", dump({[{1, 3, key = "value"}] = {true, false}}))
  end)

  -- sequences with table elements implementing _tostring

  it('{1, "text", vector(2, 4)} => "{[1] = 1, [2] = "text", [3] = vector(2, 4)}"', function ()
    assert.are_equal("{[1] = 1, [2] = \"text\", [3] = vector(2, 4)}", dump({1, "text", vector(2, 4)}, false, 1, true))
  end)

  -- non-sequence tables where ambiguous representation can be made deterministic with sorted_keys
  --   as long as the keys are comparable
  -- note that we are not testing __genOrderedIndex, orderedNext and orderedPairs, so we test them via dump with sorted_keys: true instead

  it('{f = 4, ["0"] = "a", b = -100} => "{[0] = "a", b = -100, f = 4}"', function ()
    assert.are_equal("{0 = \"a\", b = -100, f = 4}", dump({f = 4, ["0"] = "a", b = -100}, false, nil, true, --[[sorted_keys:]] true))
  end)

  -- infinite recursion prevention

  it('at level 0: {} => [table]', function ()
    assert.are_same({"[table]", "[table]"}, {dump({}, false, 0), dump({}, true, 0)})
  end)
  it('at level 1: {1, {}} => {1, [table]}', function ()
    assert.are_same({"{[1] = 1, [2] = [table]}", "[{[1] = 1, [2] = [table]}]"}, {dump({1, {}}, false, 1), dump({1, {}}, true, 1)})
  end)
  it('at level 2: {...} => "{{[1] = 1 [2] = [table] [3] = "rest"} = {idem}', function ()
    assert.are_equal("{[{[1] = 1, [2] = [table], [3] = \"rest\"}] = {[1] = 1, [2] = [table], [3] = \"rest\"}}", dump({[{1, {2, {3, {4}}}, "rest"}] = {1, {2, {3, {4}}}, "rest"}}, false, 2))
  end)
  it('without level arg, use default level (2): {...} => "{{[1] = 1 [2] = [table] [3] = "rest"} = {idem}', function ()
    assert.are_equal("{[{[1] = 1, [2] = [table], [3] = \"rest\"}] = {[1] = 1, [2] = [table], [3] = \"rest\"}}", dump({[{1, {2, {3, {4}}}, "rest"}] = {1, {2, {3, {4}}}, "rest"}}))
  end)

  -- function

  it('function => "[function]"', function ()
    local f = function ()
    end
    assert.are_same({"[function]", "[function]"}, {dump(f, false), dump(f, true)})
  end)

end)

describe('nice_dump', function ()

  it('{1, "text", vector(2, 4)} => "{[1] = 1, [2] = "text", [3] = vector(2, 4)}"', function ()
    assert.are_equal("{[1] = 1, [2] = \"text\", [3] = vector(2, 4)}", nice_dump({1, "text", vector(2, 4)}))
  end)

  it('{[10.5] = "b", [-22] = "a", [34.7] = "c"} => "{[-22] = "a", [10.5] = "b", [34.7] = "c"}"', function ()
    assert.are_equal("{[-22] = \"a\", [10.5] = \"b\", [34.7] = \"c\"}", nice_dump({[10.5] = "b", [-22] = "a", [34.7] = "c"}, true))
  end)

end)

describe('dump_sequence', function ()

  it('{1, "text", vector(2, 4)} => "{S1, "text", vector(2, 4)}"', function ()
    -- test the result directly, rather than spying on which function was used in the implementation
    assert.are_equal("{1, \"text\", vector(2, 4)}", dump_sequence({1, "text", vector(2, 4)}))
  end)

end)

describe('joinstr_table', function ()
  it('joinstr_table("_" {nil 5 "at" nil}) => "[nil]_5_at"', function ()
    assert.are_equal("[nil]_5_at", joinstr_table("_", {nil, 5, "at", nil}))
  end)
  it('joinstr_table("comma " nil 5 "at" {}) => "[nil]comma 5comma atcomma [table]"', function ()
    assert.are_equal("[nil], 5, at, [table]", joinstr_table(", ", {nil, 5, "at", {}}))
  end)
  it('joinstr_table(", ", {nil, 5, "at", {}}, nice_dump) => "[nil], 5, "at", {}"', function ()
    assert.are_equal("[nil], 5, \"at\", {}", joinstr_table(", ", {nil, 5, "at", {}}, nice_dump))
  end)
end)

describe('joinstr', function ()
  it('joinstr("", nil, 5, "at", nil) => "[nil]5at"', function ()
    assert.are_equal("[nil]5at", joinstr("", nil, 5, "at", nil))
  end)
  it('joinstr(", ", nil, 5, "at", {}) => "[nil], 5, at, [table]"', function ()
    assert.are_equal("[nil], 5, at, [table]", joinstr(", ", nil, 5, "at", {}))
  end)
end)

describe('wwrap', function ()
  -- bugfix history: +
  it('wwrap("hello", 5) => "hello"', function ()
    assert.are_equal("hello", wwrap("hello", 5))
  end)
  -- bugfix history: +
  it('wwrap("hello world", 5) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello world", 5))
  end)
  -- bugfix history: +
  it('wwrap("hello world", 10) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello world", 10))
  end)
  it('wwrap("hello world", 11) => "hello world"', function ()
    assert.are_equal("hello world", wwrap("hello world", 11))
  end)
  -- bugfix history: +
  it('wwrap("toolongfromthestart", 5) => "toolongfromthestart" (we can\'t warp at all, give up)', function ()
    assert.are_equal("toolongfromthestart", wwrap("toolongfromthestart", 5))
  end)
  it('wwrap("toolongfromthestart this is okay", 5) => "toolongfromthestart\nthis\nis\nokay" (we can\'t warp at all, give up)', function ()
    assert.are_equal("toolongfromthestart\nthis\nis\nokay", wwrap("toolongfromthestart this is okay", 5))
  end)
  it('wwrap("hello\nworld", 5) => "hello\nworld"', function ()
    assert.are_equal("hello\nworld", wwrap("hello\nworld", 5))
  end)
  it('wwrap("hello\n\nworld", 5) => "hello\n\nworld"', function ()
    assert.are_equal("hello\n\nworld", wwrap("hello\n\nworld", 5))
  end)
  it('wwrap("hello world\nhow are you today?", 8) => "hello\nworld\nhow are\nyou\ntoday?"', function ()
    assert.are_equal("hello\nworld\nhow are\nyou\ntoday?", wwrap("hello world\nhow are you today?", 8))
  end)
  it('wwrap("short\ntoolongfromthestart\nshort again", 8) => "short\ntoolongfromthestart\nshort\nagain"', function ()
    assert.are_equal("short\ntoolongfromthestart\nshort\nagain", wwrap("short\ntoolongfromthestart\nshort again", 8))
  end)
end)

describe('compute_char_size', function ()
  it('compute_char_size("hello") => (5, 1)', function ()
    assert.are_same({5, 1}, {compute_char_size("hello")})
  end)
  it('compute_char_size("hello\nworld!") => (6, 2)', function ()
    assert.are_same({6, 2}, {compute_char_size("hello\nworld!")})
  end)
  it('compute_char_size("very\n\nend\n\n") => (4, 5)', function ()
    assert.are_same({4, 5}, {compute_char_size("very\n5\nend\n\n")})
  end)
  it('compute_char_size("\nlong\nlongest  \nok") => (9, 4)', function ()
    assert.are_same({9, 4}, {compute_char_size("\nlong\nlongest  \nok")})
  end)
end)

describe('compute_size', function ()
  it('compute_size("hello") => (21, 7)', function ()
    assert.are_same({21, 7}, {compute_size("hello")})
  end)
  it('compute_size("hello\nworld!") => (25, 13)', function ()
    assert.are_same({25, 13}, {compute_size("hello\nworld!")})
  end)
  it('compute_size("very\n\nend\n\n") => (17, 31)', function ()
    assert.are_same({17, 31}, {compute_size("very\n5\nend\n\n")})
  end)
  it('compute_size("\nlong\nlongest  \nok") => (37, 25)', function ()
    assert.are_same({37, 25}, {compute_size("\nlong\nlongest  \nok")})
  end)
end)

describe('strspl', function ()
  it('strspl("", " ") => {""}', function ()
    assert.are_same({""}, strspl("", " "))
  end)
  it('strspl("hello", " ") => {"hello"}', function ()
    assert.are_same({"hello"}, strspl("hello", " "))
  end)
  it('strspl("hello world", " ") => {"hello", "world"}', function ()
    assert.are_same({"hello", "world"}, strspl("hello world", " "))
  end)
  it('strspl("hello world", "l") => {"he", "", "o wor", "d"} (multiple separators leave empty strings)', function ()
    assert.are_same({"he", "", "o wor", "d"}, strspl("hello world", "l"))
  end)
  it('strspl("hello\nworld", "\n") => {"hello", "world"}', function ()
    assert.are_same({"hello", "world"}, strspl("hello\nworld", "\n"))
  end)
  it('strspl("||a||b||", "|", false) => {"", "", "a", "", "b", "", ""}', function ()
    assert.are_same({"", "", "a", "", "b", "", ""}, strspl("||a||b||", "|", false))
  end)
  it('strspl("||a||b||", "|", true) => {"a", "b"}', function ()
    assert.are_same({"a", "b"}, strspl("||a||b||", "|", true))
  end)
  it('strspl("||a||b||c", "|", true) => {"a", "b", "c"}', function ()
    assert.are_same({"a", "b", "c"}, strspl("||a||b||c", "|", true))
  end)
  it('strspl(",;a,,b;,c", {",", ";"}, false) => {"", "", "a", "", "b", "", "c"}', function ()
    assert.are_same({"", "", "a", "", "b", "", "c"}, strspl(",;a,,b;,c", {',', ';'}, false))
  end)
  it('strspl(",;a,,b;,c", {",", ";"}, true) => {"a", "b", "c"}', function ()
    assert.are_same({"a", "b", "c"}, strspl(",;a,,b;,c", {',', ';'}, true))
  end)
  it('strspl("hello world", "lo") => {"hello world"} (multicharacter not supported)', function ()
    assert.are_same({"hello world"}, strspl("hello world", "lo"))
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
