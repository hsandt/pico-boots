-- Require all common modules that define globals and don't return a module table
-- This file plays the role of prelude in Rust, or precompiled header in C++
-- It allows to reduce token count by not needing require() for common modules in various files
-- Usage: add require("engine/common") at the top of each of your main scripts
--        it is also required in bustedhelper (after pico8api)

-- The order in which modules are required matters:
-- dependent modules should be required after their dependees
require("engine/application/constants")
require("engine/render/color")
require("engine/core/helper")
require("engine/core/class")

require("engine/core/math")

require("engine/core/vector_ext")

--#if log
require("engine/debug/dump")
--#endif
