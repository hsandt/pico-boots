--#if profiler

-- profiler window
-- usage:
-- 1. require this file as `profiler`
-- 2a. initialise stat labels with the color you want (default: white):
--      profiler.window:fill_stats(color)
--     then, each time you need to show the profiler, use:
--       profiler.window:show()
-- 2b. alternatively, use the lazy init shortcut:
--       profiler.window:show(color)
-- 3. call profiler.window:update() in your loop update
-- 4. call profiler.window:render() in your loop render
-- 5. when done, hide the profiler with:
--       profiler.window:hide()

require("engine/core/class")
require("engine/render/color")
local debug_window = require("engine/debug/debug_window")

local profiler = {}

local stats_info = {
  {"memory",     0},
  {"total cpu",  1},
  {"system cpu", 2},
  {"fps",        7},
  {"target fps", 8},
  {"actual fps", 9}
}

-- in order to align all stat values, we will draw them after the longest
-- stat name (+ a small margin)
local max_stat_name_length = 0
for stat_info in all(stats_info) do
  local stat_name = stat_info[1]
  max_stat_name_length = max(max_stat_name_length, #stat_name)
end
local stat_value_char_offset = max_stat_name_length + 1

-- return a callback function to use for stat labels
-- exposed via profiler for testing only
function profiler.get_stat_function(stat_index)
  return function()
    local stat_info = stats_info[stat_index]
    local stat_name = stat_info[1]
    -- pad stat name with spaces until it reaches a fixed length for stat value alignment
    local space_padding_size = stat_value_char_offset - #stat_name
    local space_padding = ""
    for i = 1, space_padding_size do
       space_padding = space_padding.." "
     end
    -- example: "total cpu  0.032"
    return stat_name..space_padding..stat(stat_info[2])
  end
end

profiler.stat_functions = {}
for i = 1, #stats_info do
  profiler.stat_functions[i] = profiler.get_stat_function(i)
end

profiler.window = derived_singleton(debug_window, function (self)
  self._initialized_stats = false
end)

-- add all stat labels
function profiler.window:fill_stats(c)
  c = c or colors.white
  for i = 1, #stats_info do
    self:add_label(profiler.stat_functions[i], c, 1, 1 + 6*(i-1))  -- aligned vertically
  end
  self._initialized_stats = true
end

-- helper method that replaces the base show method to lazily initialise colors
--  and show the window at the same time (color is ignored if already initialized)
function profiler.window:show(c)
  if not self._initialized_stats then
    self:fill_stats(c)
  end
  debug_window.show(self)
end

return profiler

--#endif
