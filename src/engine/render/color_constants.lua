--#if constants
--(when using replace_strings, engine constants are replaced directly so this file can be skipped)

-- default pico-8 colors

colors = {
  black = 0,
  dark_blue = 1,
  dark_purple = 2,
  dark_green = 3,
  brown = 4,
  dark_gray = 5,
  light_gray = 6,
  white = 7,
  red = 8,
  orange = 9,
  yellow = 10,
  green = 11,
  blue = 12,
  indigo = 13,
  pink = 14,
  peach = 15
}

--#else

-- dummy statement pretending we're returning a module
--  to avoid picotool failure on empty file with Travis
return nil

--(constants)
--#endif
