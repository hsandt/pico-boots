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

--[[#pico8
--#if unity
-- When doing a unity build, all modules must be concatenated in dependency, with modules relied upon
--  above modules relying on them.
-- This matters for two reasons:
--  1. Some statements are done in outer scope and rely on other modules (derived_class(), data tables defining
--   sprite_data(), table merge(), etc.) so the struct/class/function used must be defined at evaluation time,
--   and there is no picotool package definition callback wrapper to delay package evaluation to main evaluation
--   time (which is done at the end).
--  2. Even in inner scope (method calls), statements refer to named modules normally stored in local vars via
--     require. In theory, *declaring* the local module at the top of whole file and defining it at runtime
--     at any point before main is evaluation would be enough, but it's cumbersome to remove "local" in front
--     of the local my_module = ... inside each package definition, so we prefer reordering the packages
--     so that the declaration-definition is always above all usages.
-- Interestingly, ordered_require will contain the global requires listed below (keeping same order)
--  for minification lvl3, but it redundancy doesn't matter as all require calls will be stripped.

require("ordered_require")

--#endif
--#pico8]]

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
require("engine/core/math")  -- uses nice_dump from dump

-- enums
require("engine/input/input_enums")
require("engine/render/sprite")
require("engine/ui/alignments")

--#if log
require("engine/debug/logging")
--#endif
