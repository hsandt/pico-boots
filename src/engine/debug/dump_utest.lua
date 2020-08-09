require("engine/test/bustedhelper")
require("engine/debug/dump")  -- already in engine/common, but added for clarity

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
