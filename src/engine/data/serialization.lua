local serialization = {}

local blanks = {' ', '\n'}
-- for delimiters, we do not consider quotes (which are handled by parse_string_content)
--  nor opening delimiters (which *could* be checked to end token immediately, then the next parsing
--  from next_index would fail on e.g. '{' just after a key; but parse_next_expression will handle
--  these weird cases in the final assert, so no need to add more tokens in our code for that)
local blanks_and_closing_delimiters = {' ', '\n', ',', '=', ']', '}'}

-- Parse `data_string` and return expression compounded of bool, number, string, or table of one of those types
--  (including sub-tables)
-- If the optional `value_converter` callback is passed, and the expression is a table,
--  then `value_converter` is applied to each value of this table (but not of sub-tables)
-- This is the main function and should be used to parse your stringified data
function serialization.parse_expression(data_string, value_converter)
  local expression, next_index = serialization.parse_next_expression(data_string, 1)

--#if assert
  -- Verify that there is nothing left but blanks after first expression (tuples, etc. not supported,
  -- so even ',' will fail the assert)
  local next_token_start = serialization.find_token_start(data_string, next_index)
  -- because assert message is evaluated even when condition is true, we need to put the assert inside condition block
  -- to avoid error on sub() passing nil next_token_start
  if next_token_start then
    assert(false, " serialization.parse_expression: unsupported non-blank characters found after first expression '"..stringify(expression).."' at index "..next_token_start..": '"..sub(data_string, next_token_start).."'")
  end
--#endif

  if value_converter then
    assert(type(expression) == 'table', "serialization.parse_expression: value_converter passed, but parsed expression is not table")
    expression = transform(expression, value_converter)
  end

  return expression
end

-- Parse next expression in `data_string` from character starting from `from_index`,
--  until any blank or closing delimiter
--  and return (expression, next_index, has_stringified_unknown_symbol)
--  where `expression` is a bool, number, string or table
--  `next_index` is the index just after the expression (to continue parsing)
--  `has_stringified_unknown_symbol` is true when `stringify_unknown_symbols` was true
--  and has been applied (you can ignore it in the return value if you're not using stringify_unknown_symbols: true)
-- If stringify_unknown_symbols is true, a non-table, non-string, non-bool, non-number 1-token expression
--  will be converted to a string (e.g. "idle" but not "true"). This is useful for parse_next_table_entry
--  to keep a stringified version of the first expression until we know if it was a key or value (checking '=')
function serialization.parse_next_expression(data_string, from_index, stringify_unknown_symbols)
  -- Recursive approach: deeper call stack, but more compact and no need to track opening delimiter stack
  -- We also evaluate as soon as we get expressions even before checking full syntax,
  --  but since they are no heavy calculations it's OK
  local result, next_index
  local has_stringified_unknown_symbol = false

  -- Skip leading blanks until next token start
  local first_token_start = serialization.find_token_start(data_string, from_index)

  -- Get first character of this token
  -- It will tell us what kind of expression to expect
  -- Note that opening delimiters like '{' and '"' found in the middle of a token
  --  will not be checked, and simply fail in the final assert below
  -- '[' is not checked because parse_next_table_entry handles keys.
  local first_char = sub(data_string, first_token_start, first_token_start)

  -- table
  if first_char == '{' then
    -- delegate parsing of what's inside the table
    result, next_index = serialization.parse_table_content(data_string, first_token_start + 1)

  -- string
  elseif first_char == '"' or first_char == "'" then
    -- delegate parsing of what's inside the quotes
    --  (pass first_char so function knows which delimiter to expect)
    result, next_index = serialization.parse_string_content(data_string, first_token_start + 1, first_char)
  else
    -- not a table nor a string, so expect bool or number
    -- both should be written as one chunk of characters without blank, so just iterate until next blank

    next_index = serialization.find_token_post_end(data_string, first_token_start)
    local token_string = sub(data_string, first_token_start, next_index - 1)
    -- if delimiter is encounted immediately e.g. '{ ,' or '1, ,' then next_index = first_token_start and token_string is empty
    assert(#token_string > 0, "serialization.parse_next_expression: no token until blank/closing delimiter/string end '"..tostr(sub(data_string, next_index, next_index)).."' from first_token_start "..first_token_start.." to next_index "..next_index)

    -- bool
    if token_string == 'true' then
      result = true
    elseif token_string == 'false' then
      result = false
    elseif token_string ~= 'nil' then
      -- number
      local num = tonum(token_string)
      if num then
        result = num
      end

      if not result then
        if stringify_unknown_symbols then
          result = token_string
          has_stringified_unknown_symbol = true
--#if assert
        else
          -- other, invalid cases like "tru", "[123]" (since only table parser handles "[key]""),
          --  "unsupported_function(arg)", "a=2", "{a{}"
          assert(result, "serialization.parse_next_expression: token_string '"..token_string.."' is neither a table, string, bool nor number.")
--#endif
        end
      end
    end
    -- else: nil, which is already result's default value
  end

  return result, next_index, has_stringified_unknown_symbol
end

-- Parse the next table entry in `data_string` starting from `from_index`
--  `from_index` must be *inside* the table, just after the '{' or a ',' (on blank or just on
--  first expression start), else it will try to parse the table itself as a first expression (key or value)
-- Identify `value` or `key = value` syntax, stop at ',' or '}' and return tuple
--  (found_entry: bool, key, value, next_index: int)
--  with found_entry true unless '}' was found before any entry,
--  next_index at the position just *after* ',', or just *at* '}'.
-- key is nil no value is found.
-- nil value is a valid entry, in sequences it allows to skip an index.
-- Support leading and trailing spaces.
function serialization.parse_next_table_entry(data_string, from_index)
  local has_stringified_unknown_symbol, found_entry, key, value = false, false--, nil, nil

  -- Skip leading blanks until next (first) token start
  local next_index = serialization.find_token_start(data_string, from_index)

  -- Get first character of this token
  -- It will tell us what kind of expression to expect
  local first_char = sub(data_string, next_index, next_index)

  -- parse first expression (not sure if key or value for now)
  local first_expression, first_expression_str
  if first_char ~= '}' then
    -- there is something
    found_entry = true

    if first_char == '[' then
      -- expect `[key] = value` syntax
      -- delegate parsing of what's inside the key brackets (true expression)
      first_expression, next_index = serialization.parse_next_expression(data_string, next_index + 1)
      -- find next non-blank char after key expression, in case there's a blank between the expression end
      --  and ']'
      next_index = serialization.find_token_start(data_string, next_index)
      local closing_delimiter = sub(data_string, next_index, next_index)
      assert(closing_delimiter == ']', "serialization.parse_next_table_entry: expected key closing delimiter after expression "..stringify(first_expression)..", found '"..closing_delimiter.."'")
      next_index = next_index + 1
    else
      -- token immediately starts, expect `key = value` or `value` syntax
      -- unlike Lua, we don't mind key names that cannot be variable names like `32 = 64` (interpreted
      --  as `["32"] = 64`), since we always access members of parsed table data dynamically t["key"]
      --  and never with t.key (in particular because of member minification), and want to reduce token count
      -- however, we shouldn't rely on this behavior since we're supposed to stringify valid Lua tables
      -- for now, we don't know whether the expression is a key or value, but to know this, we need to parse
      --  the first expression as a real expression (in case it's a value) and then check for '='
      -- the trick we use to also support key names is to pass stringify_unknown_symbols: true
      --  so an unknown symbol will be parsed like a string in case it was a key
      --  but we keep `has_stringified_unknown_symbol` under the hand so if it happens to be a value,
      --  we can fail saying that an invalid value was passed
      first_expression, next_index, has_stringified_unknown_symbol = serialization.parse_next_expression(data_string, next_index, --[[stringify_unknown_symbols:]] true)
    end
  end
  -- else, table is empty e.g. "{  }", but we have nothing to do since
  --  found_entry defaults to false and next_index is already exactly on '}' which is what we want

  if found_entry then
    -- check if first expression is followed by '='
    next_index = serialization.find_token_start(data_string, next_index)
    assert(next_index, "serialization.parse_next_table_entry: no token found after first expression '"..dump(first_expression).."', there should at least be table end '}'")
    local delimiter = sub(data_string, next_index, next_index)
    if delimiter == '=' then
      -- we must have `key = value` or `[key] = value`, so the first expression was key
      key = first_expression
      -- expect `value` next
      next_index = serialization.find_token_start(data_string, next_index + 1)
      value, next_index = serialization.parse_next_expression(data_string, next_index)
      -- check delimiter after `value`
      next_index = serialization.find_token_start(data_string, next_index)
      delimiter = sub(data_string, next_index, next_index)
    else
--#if assert
      assert(first_char ~= '[', "serialization.parse_next_table_entry: '=' expected after key '"..stringify(first_expression).."'")
      -- surround assert with condition to avoid pre-evaluation message even when assertion passes, as if value is nil, concatenate will fail
      if has_stringified_unknown_symbol then
        assert(false, "serialization.parse_next_table_entry: an unknown symbol was met and stringified to '"..first_expression.."', but this is only valid for keys and this was actually a value")
      end
--#endif

      -- we must have `value`, so first expression was value
      -- let the caller (parse_table_content check the next delimiter and if it's valid, i.e. ',' or '}')
      value = first_expression
    end

    assert(delimiter == ',' or delimiter == '}', "serialization.parse_next_table_entry: token after entry starts with '"..delimiter.."', expected ',' or '}'")

    -- key or not, we skip the comma for next parsing
    if delimiter == ',' then
      -- there will be a next entry, just prepare the next parsing
      next_index = next_index + 1
    end
  end

  return found_entry, key, value, next_index

end

-- Return (t, next_index) where `t` is the table whose content is stored in `data_string`,
--  starting from `from_index` (should be just after '{'),
--  and `next_index` is the index just after the end of the table string's closing brace '}'.
function serialization.parse_table_content(data_string, from_index)
  -- Table to return
  local result = {}
  -- Variables to insert key/value in table
  local sequence_index, key, value, found_entry = 1--, nil, nil, nil

  -- keep looping, we'll check for table end inside the loop
  while true do
    -- parse next entry and update index to prepare parsing entry afterward
    -- if this was the last entry, from_index will point to '}' and found_entry will be false
    -- this includes edge cases: data_string at from_index contains an empty table with spaces like
    --  "{  }", or we haved reached the end of the table with a trailing comma + space "{1, 2, }"
    found_entry, key, value, from_index = serialization.parse_next_table_entry(data_string, from_index)

    -- check if no entry was found, including after trailing comma
    -- (when we always advance to next token, including after sequence value, we could also just check
    --  sub(data_string, from_index, from_index) == '}' directly)
    if not found_entry then
      assert(sub(data_string, from_index, from_index) == '}', "serialization.parse_table_content: parse_next_table_entry returned found_entry: false but sub(data_string, from_index, from_index) is '"..stringify(sub(data_string, from_index, from_index)).."', expected '}'")
      break
    end

    if key then
      -- table `key = value` syntax found
      result[key] = value
    else
      -- table `value` (for sequence) found
      -- do not use `elseif value` nor `add`, since it could do nothing on nil value
      --  and "{nil, 12}" wouldn't place 12 in 2nd position but in 1st position
      result[sequence_index] = value
      sequence_index = sequence_index + 1
    end
  end

  return result, from_index + 1
end

-- Return (str, next_index) where `str` is the string inside `data_string` started with `delimiter_quote`,
--  with content starting at `from_index`
--  and `next_index` is the index just after the end of the string's closing delimiter.
--  (1 character after the opening delimiter quote; if starting just on delimiter quote,
--  returned string will be empty)
function serialization.parse_string_content(data_string, from_index, delimiter_quote)
  for i = from_index, #data_string do
    -- Get next character
    local c = sub(data_string, i, i)

    assert(c ~= '\\', "serialization.parse_string_content: escape backslashes are not supported and are treated like backslashes in release")

    if c == delimiter_quote then
      -- sub already returns a string, nothing to convert
      -- just make sure to return the substring between the quotes, not included,
      --  and the index just after the closing quote
      return sub(data_string, from_index, i - 1), i + 1
    end
  end
  assert(false, "serialization.parse_string_content: missing matching quote `"..delimiter_quote.."` until the end, string `"..sub(data_string, from_index).."` is never closed")
end

-- Return index of first character in `data_string` that is contained in `chars` set (sequence)
--  starting from `from_index`.
-- If `negative` is true, chars become a negative set and return the first character
--  that is *not* in the set.
-- Return nil if no match is found.
function serialization.find_char(data_string, from_index, chars, negative)
  -- default negative is nil, and not nil is true, so it allows us to do a positive search by default
  for i = from_index, #data_string do
    -- Get next character
    local c = sub(data_string, i, i)
    -- Check for first matching character
    local is_matching = contains(chars, c)
    if not negative and is_matching or negative and not is_matching then
      return i
    end
  end
end

-- Return index of first non-blank character in `data_string`, searching from `from_index` (included)
-- Use this to effectively swallow blanks and advance your iterating index to the next token.
-- Return nil if no token is found.
function serialization.find_token_start(data_string, from_index)
  return serialization.find_char(data_string, from_index, blanks, true)
end

-- Return index of first blank character in `data_string`, searching from `from_index` (included)
-- Use this to effectively swallow tokens and advance your iterating index to 1 char after the end
-- of the current token (we assume we start from a token position), hence "post end" (end in the C-sense)
-- Return #data_string + 1 if no match is found, so the index is usable to extract token substring
function serialization.find_token_post_end(data_string, from_index)
  local first_blank = serialization.find_char(data_string, from_index, blanks_and_closing_delimiters)
  return first_blank and first_blank or #data_string + 1
end

return serialization
