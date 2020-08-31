require("engine/test/bustedhelper")
local serialization = require("engine/data/serialization")

describe('serialization', function ()

  describe('parse_expression', function ()

    it('should parse and return: nil', function ()
      assert.is_nil(serialization.parse_expression([[  nil  ]]))
    end)

    it('should parse and return a bool: true', function ()
      assert.are_equal(true, serialization.parse_expression([[  true  ]]))
    end)

    it('should parse and return a bool: false', function ()
      assert.are_equal(false, serialization.parse_expression([[  false  ]]))
    end)

    it('should parse and return a number', function ()
      assert.are_equal(123, serialization.parse_expression([[  123  ]]))
    end)

    it('should parse and return a string with single quotes', function ()
      assert.are_equal("test", serialization.parse_expression([[  'test'  ]]))
    end)

    it('should parse and return a string with double quotes', function ()
      assert.are_equal("test", serialization.parse_expression([[  "test"  ]]))
    end)

    it('should parse and return a string with double quotes', function ()
      assert.are_same({1, 2, 3}, serialization.parse_expression([[  {1, 2, 3}  ]]))
    end)

    it('should parse and return a table mixing keys, sequenced values and sub-tables', function ()
      assert.are_same({1, hello = "world", [32] = {1, b = false}, 5, {true}}, serialization.parse_expression([[  {1, hello = "world", [32] = {1, b = false}, 5, {true}}  ]]))
    end)

    it('should fail parsing: falsed', function ()
      assert.has_error(function ()
        serialization.parse_expression([[falsd]])
      end)
    end)

    -- the ultimate test for this function
    it('should parse and return a table mixing keys, sequenced values and sub-tables on multiple lines', function ()
      -- of course, 5 and {true} are resequenced on indices 2 and 3, but it was easier to copy-paste
      -- the data string (without newlines) preserving order to check the result
      assert.are_same({1, hello = "world", [32] = {1, b = 'single'}, 5, {true}}, serialization.parse_expression([[
        {
          1,
          hello = "world",
          [32] = {
            1,
            b = 'single'
          },
          5,
          {true}
        }
        ]]))
    end)

    it('should fail parsing multiple expressions separated by blank', function ()
      assert.has_error(function ()
        serialization.parse_expression([[true false]])
      end)
    end)

    it('should fail parsing multiple expressions separated by comma (tuple)', function ()
      assert.has_error(function ()
        serialization.parse_expression([[true, false]])
      end)
    end)

    it('should apply converter callback when expression is a table)', function ()
      local function square(x)
        return x * x
      end

      assert.are_same({100, a = 4}, serialization.parse_expression([[{10, a = -2}]], square))
    end)

    it('should fail passing a converter callback when expression is not a table)', function ()
      local function converter()
      end

      assert.has_error(function ()
        serialization.parse_expression([[10]], converter)
      end)
    end)

  end)

  describe('parse_next_expression', function ()

    it('should parse and return: nil, post end at comma, from anywhere in the data string', function ()
      assert.are_same({nil, 7, false}, {serialization.parse_next_expression([[)  nil,  ]], 2)})
    end)

    it('should parse and return bool: true, post end at comma, from anywhere in the data string', function ()
      assert.are_same({true, 8, false}, {serialization.parse_next_expression([[)  true,  ]], 2)})
    end)

    it('should parse and return bool: false, post end, from anywhere in the data string', function ()
      assert.are_same({false, 13, false}, {serialization.parse_next_expression([[)=54,  false=  ]], 6)})
    end)

    it('should parse and return a number, post end, from anywhere in the data string', function ()
      assert.are_same({123, 11, false}, {serialization.parse_next_expression([[)abc   123]   ]], 5)})
    end)

    it('should parse and return stringified unknown symbol, post end with stringify_unknown_symbols: true', function ()
      assert.are_same({"unknown", 11, true}, {serialization.parse_next_expression([[)  unknown  ]], 2, true)})
    end)

    it('should error when unknown symbol is met but stringify_unknown_symbols: false', function ()
      assert.has_error(function ()
        serialization.parse_next_expression([[)  unknown  ]], 1)
      end)
    end)

    it('should parse and return a string with single quotes', function ()
      assert.are_same({"test", 8, false}, {serialization.parse_next_expression([[ 'test' ]], 2)})
    end)

    it('should parse and return a string with double quotes', function ()
      assert.are_same({"test", 8, false}, {serialization.parse_next_expression([[ "test" ]], 2)})
    end)

    it('should parse and return an empty table', function ()
      assert.are_same({{}, 4, false}, {serialization.parse_next_expression([[){}]], 2)})
    end)

    -- the ultimate test for this function
    it('should parse and return a table mixing keys, sequenced values and sub-tables on multiple lines; index after }; false as no stringification', function ()
      -- of course, 5 and {true} are resequenced on indices 2 and 3, but it was easier to copy-paste
      -- the data string (without newlines) preserving order to check the result
      assert.are_same({{1, hello = "world", [32] = {1, b = 'single'}, 5, {true}}, 162, false}, {serialization.parse_next_expression([[
        {
          1,
          hello = "world",
          [32] = {
            1,
            b = 'single'
          },
          5,
          {true}
        }
        ]], 9)})
    end)

  end)

  describe('parse_next_table_entry', function ()

    it('should parse and return first entry: 1, next index just after comma', function ()
      assert.are_same({true, nil, 1, 4}, {serialization.parse_next_table_entry("{1, 2 ,  3 }", 2)})
    end)

    it('should parse and return second entry: 2, next index just after comma', function ()
      assert.are_same({true, nil, 2, 8}, {serialization.parse_next_table_entry("{1, 2 ,  3 }", 4)})
    end)

    it('should parse and return third entry: 3, next index just at }', function ()
      assert.are_same({true, nil, 3, 12}, {serialization.parse_next_table_entry("{1, 2 ,  3 }", 8)})
    end)

    it('should parse and return third entry: 3, next index just at }', function ()
      assert.are_same({true, nil, nil, 9}, {serialization.parse_next_table_entry("{1, nil, 3 }", 4)})
    end)

    it('should parse and return second entry: ["health"] = 2, next index just at }', function ()
      assert.are_same({true, "health", 2, 20}, {serialization.parse_next_table_entry("{1, ['health'] = 2, 3 }", 4)})
    end)

    it('should parse and return second entry: (stringified) health = 2, next index just at }', function ()
      assert.are_same({true, "health", 2, 16}, {serialization.parse_next_table_entry("{1, health = 2, 3 }", 4)})
    end)

    it('should parse and return second entry: [32] = 2, next index just at }', function ()
      assert.are_same({true, 32, 2, 14}, {serialization.parse_next_table_entry("{1, [32] = 2, 3 }", 4)})
    end)

    it('(supported, unlike native Lua!) should parse and return second entry: (stringified) 32 = 2, next index just at }', function ()
      assert.are_same({true, 32, 2, 12}, {serialization.parse_next_table_entry("{1, 32 = 2, 3 }", 4)})
    end)

    it('should parse and return found_entry: false, next index just at }', function ()
      assert.are_same({false, nil, nil, 8}, {serialization.parse_next_table_entry("{1, 2, }", 7)})
    end)

    it('should parse and return found_entry: false', function ()
      assert.are_same({false, nil, nil, 3}, {serialization.parse_next_table_entry("{ } ", 2)})
    end)

    it('should fail parsing an uknown symbol used as value (invalid stringification)', function ()
      assert.has_error(function ()
        serialization.parse_next_table_entry([[{unknown}]], 2)
      end)
    end)

  end)

  describe('parse_table_content', function ()

    it('should parse and return an empty table', function ()
      assert.are_same({{}, 5}, {serialization.parse_table_content([[  {}  ]], 4)})
    end)

    it('should parse and return a sequence', function ()
      assert.are_same({{true, 2, "hello"}, 21}, {serialization.parse_table_content([[  {true, 2, "hello"}  ]], 4)})
    end)

    it('should parse and return a table with keys', function ()
      assert.are_same({{a = 1, [32] = "hello"}, 26}, {serialization.parse_table_content([[  {a = 1, [32] = 'hello'}  ]], 4)})
    end)

    -- the ultimate test for this function
    it('should parse and return a table mixing keys, sequenced values and sub-tables on multiple lines; index after }', function ()
      -- of course, 5 and {true} are resequenced on indices 2 and 3, but it was easier to copy-paste
      -- the data string (without newlines) preserving order to check the result
      assert.are_same({{1, hello = "world", [32] = {1, b = 'single'}, 5, {true}}, 162}, {serialization.parse_table_content([[
        {
          1,
          hello = "world",
          [32] = {
            1,
            b = 'single'
          },
          5,
          {true}
        }
        ]], 10)})
    end)

    it('should fail on starting comma', function ()
      assert.has_error(function ()
        serialization.parse_table_content([[  {,}  ]], 4)
      end)
    end)

    it('should fail on 2 chained commas', function ()
      assert.has_error(function ()
        serialization.parse_table_content([[  {1,,}  ]], 4)
      end)
    end)

  end)

  describe('parse_string_content', function ()

    it('should parse and return a string with single quotes', function ()
      assert.are_equal("hello", serialization.parse_string_content([[    'hello'   ]], 6, "'"))
    end)

    it('should parse and return a string with double quotes', function ()
      assert.are_equal("hello", serialization.parse_string_content([[  "hello"  ]], 4, '"'))
    end)

    it('should fail to parse a string with no closing quote', function ()
      assert.has_error(function ()
        serialization.parse_string_content([[  "hello  ]], 4, '"')
      end)
    end)

    it('should fail to parse a string with escape backslash', function ()
      assert.has_error(function ()
        serialization.parse_string_content([[  hello \"world\" " ]], 4, '"')
      end)
    end)

  end)

  describe('#mute parse_trimmed_data_string', function ()

    it('should parse and return a bool: true', function ()
      assert.are_equal(true, serialization.parse_table_string("true"))
    end)

  end)

  describe('find_char', function ()

    it('(positive search) should find the index of the first char in chars starting at from_index', function ()
      -- the 'o' in "world" is at index 8
      assert.are_equal(8, serialization.find_char("hello world", 6, {'o', 'l'}))
    end)

    it('(negative search) should find the index of the first char not in chars starting at from_index', function ()
      -- the 'r' in "world" is at index 9
      assert.are_equal(9, serialization.find_char("hello world", 6, {' ', 'o', 'w'}, true))
    end)

  end)

  describe('find_token_start', function ()

    it('should find the index of the first non-blank char starting at from_index', function ()
      -- the 'w' in "world" is at index 11
      assert.are_equal(11, serialization.find_token_start("  hello   world   !!", 8))
    end)

  end)

  describe('find_token_post_end', function ()

    it('should find the index of the first blank/closing delimiter char starting at from_index: " "', function ()
      -- the ' ' just after "world" is at index 15
      assert.are_equal(15, serialization.find_token_post_end("  hello  world  !!  ", 11))
    end)

    it('should find the index of the first blank/closing delimiter char starting at from_index: ","', function ()
      -- the ',' just after "world" is at index 15
      assert.are_equal(15, serialization.find_token_post_end("  hello  world,  !!  ", 11))
    end)

  end)

end)
