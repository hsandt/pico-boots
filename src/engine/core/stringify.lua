-- SUPERSEDED by defining metatable __tostring and just using tostr, since PICO-8 0.2.0+
--  has fixed tostr() not using __tostring
function stringify(value)
  if type(value) == 'table' and value._tostring then
    return value:_tostring()
  else
    return tostr(value)
  end
end
