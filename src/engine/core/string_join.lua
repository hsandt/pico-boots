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
