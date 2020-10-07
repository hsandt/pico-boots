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

-- The order in which modules are required matters:
-- dependent modules should be required after their dependees
require("engine/application/constants")
require("engine/render/color")
require("engine/core/helper")
require("engine/core/class")

require("engine/core/math")
require("engine/debug/dump")

--#if tostring
require("engine/core/string_join")
--#endif

--#if log
require("engine/debug/logging")
--#endif
