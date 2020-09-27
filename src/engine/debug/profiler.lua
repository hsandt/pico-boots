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

local debug_window = require("engine/debug/debug_window")
local wtk = require("wtk/pico8wtk")

local profiler = {}

local stats_info = {
  {"memory",     0},
  {"total cpu",  1},
  {"system cpu", 2},
  {"fps",        7},
  {"target fps", 8},
  {"actual fps", 9}
}

-- may be members of profiler, but it's not a true singleton
--  so no way to reset those values with a proper init (although could be reset manually)
--  so we might as well have them local and not test them for now
local min_cpu_found, max_cpu_found = 99, 0
-- count the first frames that tend to be slower due to loading, to ignore them
local initial_frames_count = 0

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

-- update cpu extrema with current value and return it as a range string
-- note that this is currently not covered due to min_cpu_found/max_cpu_found
--  being local, although luacov consider it covered because showing the wtk
--  panel evaluates it once (and we cannot just stub it as it's referenced to dynamically)
function profiler.update_and_get_cpu_extrema_function()
  local total_cpu = stat(1)
  min_cpu_found = min(min_cpu_found, total_cpu)
  -- ignore first, very long frames on initial load
  if initial_frames_count > 10 then
    max_cpu_found = max(max_cpu_found, total_cpu)
  else
    initial_frames_count = initial_frames_count + 1
  end

  -- example: "cpu extrema 0.42-0.84"
  return "cpu extrema "..min_cpu_found.."-"..max_cpu_found
end

profiler.stat_functions = {}
for i = 1, #stats_info do
  profiler.stat_functions[i] = profiler.get_stat_function(i)
end
profiler.stat_functions[#stats_info + 1] = profiler.update_and_get_cpu_extrema_function

profiler.window = derived_singleton(debug_window, function (self)
  self.initialized_stats = false
  self.panel = wtk.panel.new(103, 40, 0, true)
  self.gui:add_child(self.panel, 0, 0)
end)

-- add all stat labels
function profiler.window:fill_stats(c)
  c = c or colors.white
  for i = 1, #stats_info + 1 do
    local label = wtk.label.new(profiler.stat_functions[i], c)
    -- align vertically (consider using vertical_layout)
    y = 6*(i-1) + 2  -- margin
    self.panel:add_child(label, 2, y)
  end
  self.initialized_stats = true
end

-- helper method that replaces the base show method to lazily initialise colors
--  and show the window at the same time (color is ignored if already initialized)
function profiler.window:show(c)
  if not self.initialized_stats then
    self:fill_stats(c)
  end
  debug_window.show(self)
end

--#endif

-- prevent busted from parsing both versions of profiler
--[[#pico8

-- fallback implementation if profiler symbol is not defined
-- (picotool fails on empty file due to empty self._tokens)
--#ifn profiler
local profiler = {"symbol profiler is undefined"}
--#endif

--#pico8]]

return profiler
