-- Require all common modules that define globals and don't return a module table
-- This file plays the role of prelude in Rust, or precompiled header in C++
-- It allows to reduce token count by not needing require() for common modules in various files
require("engine/application/constants")
require("engine/core/class")
require("engine/core/helper")
require("engine/core/math")
require("engine/core/vector_ext")
