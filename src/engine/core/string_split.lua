-- Split a string s into sub-strings separated by sep, and return the sequence of sub-strings
-- ! prefer using PICO-8 v0.2.1's split when possible, i.e. you don't need
-- ! table multi-separators nor collapse behavior (this will spare you string_split include
-- ! and therefore precious characters), and also if you need convert_numbers
-- separator must be either:
--  - a single character
--  - a sequence of single characters
-- parameter collapse:
--  if true, collapse consecutive separators into a big one
--  if false or nil, handle each separator separately,
--   adding an empty string between each consecutive pair
-- note: we prefer using a sequence of single characters {',', ';'} rather than
--  a string coumpounded of the single char separators ",;", because
--  we have a sequence `contains` method but no string `contains` method
--  and also in case we want to add multi-char separator strings later
-- ex1: strspl("|a||b", '|')        => {"", "a", "", "b"}
-- ex2: strspl("|a||b", '|', true)  => {"a", "b"}
-- ex2: strspl("a,b;c", {',', ";"}) => {"a", "b", "c"}
function strspl(s, sep, collapse)
  local sub_strings = {}
  local buffer = ""

  for i = 1, #s do
    local c = sub(s, i, i)
    -- support multi-separators: if sep is table, check if any of its elements matches c
    -- else, check if c is the separator itself
    -- however, we don't support empty separator to explode string into individual characters
    --  like PICO-8 v0.2.1b's split (this function was created before split was added)
    local is_sep = type(sep) == "table" and contains(sep, c) or c == sep
    if is_sep then
      -- detected separator
      if #buffer > 0 or not collapse then
        -- split here, add sub-string obtained so far to sub_strings sequence
        add(sub_strings, buffer)
        buffer = ""
      end
    else
      -- concatenate current character to sub-string buffer
      buffer = buffer..c
    end
  end

  -- if some characters are left in sub-string buffer, we should add them
  --  as final element in the sub-string sequence
  -- if the buffer is empty (possible if s was empty, or s ended with a separator character)
  --  and we are not collapsing, then we must still add this empty sub-string to the end
  --  of the sequence
  if #buffer > 0 or not collapse then
    add(sub_strings, buffer)
  end

  return sub_strings
end
