-- String helpers

-- Upper/lower conversion. PICO-8 reverses case by displaying lower characters as big upper chars,
--   and upper characters as small upper chars (scaled down a bit, but same shape as upper chars).
-- https://www.lexaloffle.com/bbs/?tid=3217
-- although we do the reverse of what is suggested (small to big) since we just want to sanitize
--   copy-pasted strings that contain upper-case characters into pure lower-case characters
--   (so they appear big in PICO-8)
local small_to_big_chars = {}
-- upper A to Z character codes (displayed as smaller A to Z in PICO-8)
local small_chars = "\65\66\67\68\69\70\71\72\73\74\75\76\77\78\79\80\81\82\83\84\85\86\87\88\89\90"
local big_chars = "abcdefghijklmnopqrstuvwxyz"
for i=1,26 do
  small_to_big_chars[sub(small_chars, i, i)] = sub(big_chars, i, i)
end

function to_big(str)
  local big_str = ""
  for i = 1, #str do
    local c = sub(str, i, i)
    if c >= "\65" and c <= "\90" then
      big_str = big_str..small_to_big_chars[c]
    else
      big_str = big_str..c
    end
  end
  return big_str
end

--#if deprecated
-- deprecated: use tonum instead, whose bug (0x0000.0001 offset on negative values)
-- was fixed in PICO-8 0.1.12
function string_tonum(val)
  warn("string_tonum is deprecated, use tonum instead")
  return tonum(val)
end
--#endif

-- joinstr_table below is useful for assert-only builds, so not placed inside #if log.
-- Actually, the most efficient would be #if log || assert but we don't support "||" yet,
--   and it's annoying to write the same block of code twice, inside #if log then inside #if assert.
-- Since the function is not too long, we consider it's okay to keep it in release instead.

-- concatenate a sequence of strings or stringables with a separator
-- embedded nil values won't be ignored, but nils at the end will be
-- if you need to surround strings with quotes, pass string_converter = nice_dump
--   but be careful not to use that in _tostring if one of the members are class/struct
--   themselves, as it may cause infinite recursion on _tostring => nice_dump => _tostring
function joinstr_table(separator, args, string_converter)
  string_converter = string_converter or stringify

  local n = #args

  local joined_string = ""

  -- iterate by index instead of for all, so we don't skip nil values
  -- and #n (which counts nil values) match the used index
  for index = 1, n do
    joined_string = joined_string..string_converter(args[index])
    if index < n then
      joined_string = joined_string..separator
    end
  end

  return joined_string
end

-- variadic version
-- (does not support string converter due to parameter being at the end)
function joinstr(separator, ...)
  return joinstr_table(separator, {...})
end

-- https://pastebin.com/NS8rxMwH
-- converted to clean lua, adapted coding style
-- changed behavior:
-- - avoid adding next line if first word of line is too long
-- - don't add trailing space at end of line
-- - don't add eol at the end of the last line
-- - count the extra separator before next word in the line length prediction test
-- i kept the fact that we don't collapse spaces so 2x, 3x spaces are preserved

-- word wrap (string, char width)
function wwrap(s,w)
  local retstr = ''
  local lines = strspl(s, '\n')
  local nb_lines = count(lines)

  for i = 1, nb_lines do
    local linelen = 0
    local words = strspl(lines[i], ' ')
    local nb_words = count(words)

    for k = 1, nb_words do
      local wrd = words[k]
      local should_wrap = false

      if k > 1 then
        -- predict length after adding 1 separator + next word
        if linelen + 1 + #wrd > w then
          -- wrap
          retstr = retstr..'\n'
          linelen = 0
          should_wrap = true
        else
          -- don't wrap, so add space after previous word if not the first one
          retstr = retstr..' '
          linelen = linelen + 1
        end
      end

      retstr = retstr..wrd
      linelen = linelen + #wrd
    end

    -- wrap following \n already there
    if i < nb_lines then
      retstr = retstr..'\n'
    end
  end

  return retstr
end

-- return (number of chars in the longest line, number of lines),
--   in a multi-line string
-- logic is close to wtk.label.compute_size but does not multiply by char size
--   to return size in pixels
function compute_char_size(text)
  local lines = strspl(text, '\n')
  nb_lines = #lines

  local max_nb_chars = 0
  for line in all(lines) do
    max_nb_chars = max(max_nb_chars, #line)
  end

  return max_nb_chars, nb_lines
end

-- return (width, height) of a multi-single string,
--   adding a margin of 1px in each direction (to easily frame in rectangle)
-- result is close to wtk.label.compute_size but with extra 2px
--   in width and height
function compute_size(text)
  local max_nb_chars, nb_lines = compute_char_size(text)
  return max_nb_chars * character_width + 1, nb_lines * character_height + 1
end

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
