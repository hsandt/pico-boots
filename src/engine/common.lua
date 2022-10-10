-- Require all engine common modules (used across various engine scripts)
--  that define globals and don't return a module table
-- This file plays the role of prelude in Rust, or precompiled header in C++
-- It allows to reduce token count by not needing require() for common modules in various files
-- Note: this only concerns modules actually used by other engine modules
--  For engine and game modules used across your game project, please create
--  your own game_src/common.lua that requires any extra common module for your game.
--  Basically, below is the minimal set for all engine modules to work properly + provide debug
--   information if #assert is defined
--  (it is not often to make all engine utests pass because utests use some additional helpers
--  like clear_table)
--  *excluding*
-- Usage: add require("engine/common") at the top of each of your main scripts
--        it is also required in bustedhelper (after pico8api)

-- The only case where you wouldn't want to require this script is when
--  you only use a very small subset for engine scripts, one that would require fewer
--  scripts that the list below. In this case, I recommend to make your own game_src/common.lua
--  and add both engine and game common dependencies there.

--#if minify_level3
-- Minify level 3 uses option -GF to shorten globals,
--  but declaration must be placed before any usage.
-- Since common is the top-most module to actually call require
--  in a picotool build, just add a dummy definition here,
--  but it would still be called *after* the true definition at the bottom
--  of the built file (only parsing would be done early), so make it
--  unreachable with `if false` (it won't be stripped away)
-- Note that we use assignment here so technically -G is doing the job
--  despite require being a global function.
-- Place this *above* all require calls so they can be minified properly.
if nil then
  require = 0
end
--#endif

-- The order in which modules are required matters:
--  dependent modules should be required after their dependees.
-- This is even more important with minify_level3 as even if dependee functions
--  are called inside another function's body, global variable assignment scanning
--  still goes top to bottom and needs to find assignments first.
require("engine/application/constants")
require("engine/render/color")
require("engine/core/helper")
require("engine/core/stringify")
--#if tostring
require("engine/core/string_join")  -- uses stringify from class
--#endif
require("engine/debug/dump")  -- uses joinstr_table from string_join
require("engine/core/class")  -- uses nice_dump from dump
require("engine/core/math")   -- uses nice_dump from dump

-- enums
require("engine/input/input_enums")
require("engine/render/sprite_rotate90")
require("engine/ui/alignments")

--#if log
-- Logging is normally a module to assign locally as local logging = ...
--  but since it also has global functions log/warn/err used commonly, it's worth requiring as global
-- If you need to access the logging object though, you should still require this with local logging = ...
--  in the file where you need it. Of course, after unify it doesn't matter, but it's still useful
--  to pass utests properly.
require("engine/debug/logging")
--#endif
