--#if tuner

local wtk = require("wtk/pico8wtk")

--[[
Code tuner:
  a debug utility that allows to tune
  any value in code by using a small widget on screen

Usage:
  To include:
    local codetuner = require("engine/debug/codetuner")

  Note the absence of "--#if tuner". codetuner has its own preprocessor
  switch to revert all tuned variables to their default values on release
  (see bottom of this script).

  Then in your main init:
    --#if tuner
    codetuner:show()
    codetuner.active = true
    --#endif

  During development, where you need to test different
  numerical values in your code, use `tuned("my var", default_value)`
  instead of `default_value`. as long as you reuse the same variable
  name, you can reuse the same tunable variable at different places.

  Note that the default value is ignored after the first time the
  tuned variable is encountered, so we recommend passing the same
  default value for all occurrences in case the execution order is
  undetermined.

  Then build the game defining the `tuner` symbol,
  use the number selection widget for entry "my var" to tune it
--]]


-- a trick we use because singleton don't have their methods defined during the first init:
-- define an init method as an external function before singleton definition + instantiation,
--  then call it on (self: singleton instance) during init
local function init_window(self)
  self.gui = wtk.gui_root.new()
  self.gui.visible = false
  self.main_panel = wtk.panel.new(1, 1, colors.peach, true)
  self.gui:add_child(self.main_panel)

  -- todo: add checkbox to toggle active state
end

local codetuner = singleton(function (self)
    -- parameters

    -- if true, tuned values are used, else default values are used
    self.active = false

    -- state vars

    -- table of tuned variables, identified by their names
    -- to simplify, tuned variables are not objects but mere numbers
    -- in counterpart, it's not possible to add meta-info like individual tuned var disabling
    self.tuned_vars = {}

    -- gui
    self.gui = nil
    self.main_panel = nil

    -- init_window is required to add tuned var widgets in the background,
    --  so even if codetuner window is shown later, widgets will be ready
    init_window(self)
end)

-- still bind the method afterward to be cleaner and allow testing
codetuner.init_window = init_window

-- utilities from widget toolkit demo

-- return a new position on the right of a widget w at position (x, y), of width w, plus a margin dist
function codetuner.next_to(w, dist)
 return w.x+w.w+(dist or 2), w.y
end

-- return a new position below a widget w at position (x, y), of height h, plus a margin dist
function codetuner.below(w, dist)
 return w.x, w.y+w.h+(dist or 2)
end

-- todo: use this struct for easier variable handling
-- tuned variable struct, represents a variable to tune in the code tuner
-- currently unused, it will replace the free vars in codetuner.tuned_vars
-- to provide better information (type, range, default value)
codetuner.tuned_variable = new_struct()

-- name           string   tuned variable identifier
-- default_value  any      value used for tuned variable if codetuner is inactive
function codetuner.tuned_variable:init(name, default_value)
  self.name = name
  self.default_value = default_value
end

--#if tostring
-- return a string with format: tuned_variable "{name}" (default: {default_value})
function codetuner.tuned_variable:_tostring(name, default_value)
  return "tuned_variable \""..self.name.."\" (default: "..self.default_value..")"
end
--#endif

-- return a function callback for the spinner, that sets the corresponding tuned variable
-- exposed via codetuner for testing
function codetuner:get_spinner_callback(tuned_var_name)
  return function (spinner)
    self:set_tuned_var(tuned_var_name, spinner.value)
  end
end

-- if codetuner is active, retrieve tuned var or create a new one with default value if needed
-- if codetuner is inactive, return default value
function codetuner:get_or_create_tuned_var(name, default_value, step)
  if self.active then
    -- booleans may be used, so always compare to nil
    if self.tuned_vars[name] == nil then
      self:create_tuned_var(name, default_value, step)
    end
    return self.tuned_vars[name]
  else
    return default_value
  end
end

-- Create a tuned variable
-- Note that unlike get_or_create_tuned_var, it doesn't check if codetuner is active.
function codetuner:create_tuned_var(name, default_value, step)
  assert(default_value, "codetuner:create_tuned_var: default_value is "..tostr(default_value)..", expected integer")
  -- as a fallback, at least use 0 or the entry will be nil,
  --  so next time we try to get_or_create_tuned_var a value with the same name
  --  it will create another one, indefinitely
  default_value = default_value or 0

  self.tuned_vars[name] = default_value

  -- register to ui
  local next_pos_x, next_pos_y
  if #self.main_panel.children > 0 then
    next_pos_x, next_pos_y = codetuner.below(self.main_panel.children[#self.main_panel.children])
  else
    next_pos_x, next_pos_y = 1, 1
  end
  local var_label = wtk.label.new(name)
  local tuning_spinner = wtk.spinner.new(-999, 999, default_value, step, self:get_spinner_callback(name))
  self.main_panel:add_child(var_label, next_pos_x, next_pos_y)
  next_pos_x, next_pos_y = codetuner.below(self.main_panel.children[#self.main_panel.children])
  self.main_panel:add_child(tuning_spinner, next_pos_x, next_pos_y)
end

-- set tuned variable, even if codetuner is inactive
-- fails with warning if name doesn't exist
function codetuner:set_tuned_var(name, value)
  if self.tuned_vars[name] ~= nil then
    self.tuned_vars[name] = value
  else
    warn("codetuner:set_tuned_var: no tuned var found with name: "..tostr(name), 'codetuner')
  end
end

-- short global alias for codetuner:get_or_create_tuned_var
function tuned(name, default_value, step)
  return codetuner:get_or_create_tuned_var(name, default_value, step)
end

function codetuner:show()
  self.gui.visible = true
end

function codetuner:hide()
  self.gui.visible = false
end

function codetuner:update_window()
  self.gui:update()
end

function codetuner:render_window()
  -- reset camera to make sure code tuner window is not affected by game camera
  camera()
  self.gui:draw()
end

--#endif

-- prevent busted from parsing both versions of codetuner
--[[#pico8

--#ifn tuner

local codetuner = {}

-- if tuner is disabled, use default value
function tuned(name, default_value)
  return default_value
end

--#endif

--#pico8]]

return codetuner
