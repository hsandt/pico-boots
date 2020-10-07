-- port of lua string.split(string, separator)
-- separator must be either:
--  - a single character
--  - a sequence of single characters
-- note: we prefer using a sequence of single characters {',', ';'} rather than
--  a string coumpounded of the single char separators ",;", because
--  we have a sequence `contains` method but no string `contains` method
--  and also in case we want to add multi-char separator strings later
-- added parameter collapse:
--  if true, collapse consecutive separators into a big one
--  if false or nil, handle each separator separately,
--   adding an empty string between each consecutive pair
-- ex1: strspl("|a||b", '|')       => {"", "a", "", "b"}
-- ex2: strspl("|a||b", '|', true) => {"a", "b"}
-- ex2: strspl("a,b;c", {',', ";"}) => {"a", "b", "c"}
function strspl(s, sep, collapse)
  local ret = {}
  local buffer = ""

  for i = 1, #s do
    local c = sub(s, i, i)
    -- support multi-separators: if sep is table, check if any of its elements matches c
    -- else, check if c is the separator itself
    local is_sep = type(sep) == "table" and contains(sep, c) or c == sep
    if is_sep then
      if #buffer > 0 or not collapse then
        add(ret, buffer)
        buffer = ""
      end
    else
      buffer = buffer..c
    end
  end
  if #buffer > 0 or not collapse then
    add(ret, buffer)
  end
  return ret
end
