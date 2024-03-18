--#if constants
--(when using replace_strings, engine constants are replaced directly so this file can be skipped)

-- define api.print as an alias for native PICO-8 print
-- this is just to avoid overriding Lua's native print (and api.print is defined
-- in pico8api.lua with a dummy implementation so busted tests can run, even though
-- we eventually stub api.print to check behavior)
-- in practice, this is only used for prebuild substitution and never called at runtime
-- (this module body is stripped from build anyway)
-- note: we must isolate table entries on their own line so replace_strings.py parser works

api = {
  print = print,
}

-- common pico-8 constants

-- screen
screen_width = 128
screen_height = 128

-- tilemap
tile_size = 8
-- useful if you use region reload system
map_region_tile_width = 128
map_region_tile_height = 32  -- we don't use shared data so stop at 32
map_region_width  = 1024     -- map_region_tile_width  * tile_size
map_region_height = 256      -- map_region_tile_height * tile_size

-- default character dimensions (including separator space)
-- when using custom font, get them from peek(0x5600)/peek(0x5602) resp.,
--  or if working directly with text strings, use text_helper.compute_single_line_text_width
--  and compute_char_height
character_width = 4
character_height = 6
-- for characters \128 and beyond
wide_character_width = 8

-- time
fps60 = 60
fps30 = 30
delta_time60 = 1/60 -- = 0x0000.0444 = 0.01666259765625
delta_time30 = 1/30 -- = 0x0000.0888 = 0.0333251953125

--#else

-- dummy statement pretending we're returning a module
--  to avoid picotool failure on empty file with Travis
return nil

--(constants)
--#endif
