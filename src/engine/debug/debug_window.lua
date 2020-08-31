local wtk = require("wtk/pico8wtk")

-- base class for debug windows
-- usage: derive from debug_window and implement on_init
-- create gui root, invisible
-- gui    gui_root     root of the debug window gui
debug_window = singleton(function (self)
  self.gui = wtk.gui_root.new()
  self.gui.visible = false
end)

function debug_window:show()
  self.gui.visible = true
end

function debug_window:hide()
  self.gui.visible = false
end

function debug_window:update()
  self.gui:update()
end

function debug_window:render()
  camera()
  self.gui:draw()
end

function debug_window:add_label(text, c, x, y)
  local label = wtk.label.new(text, c)
  self.gui:add_child(label, x, y)
end

return debug_window
