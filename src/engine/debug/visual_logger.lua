--#if visual_logger

-- visual logger
-- log stream that prints messages to a window line by line
--
-- usage:
-- local logging = require("engine/debug/logging")
-- local vlogger = require("engine/debug/visual_logger")
-- logging.logger:register_stream(vlogger.vlog_stream)
-- vlogger.window:show()

require("engine/core/class")
require("engine/core/datastruct")
require("engine/render/color")
local debug_window = require("engine/debug/debug_window")
local logging = require("engine/debug/logging")
local wtk = require("wtk/pico8wtk")

local vlogger = {
  default_buffer_size = 5
}

-- non-inherited members
-- _initialized_msg_queue  bool             true iff _msg_queue has been set
-- _msg_queue              circular_buffer  queue of logged message, only the last N are shown
-- v_layout                vertical_layout  layout containing messages to display
vlogger.window = derived_singleton(debug_window, function (self)
  self._initialized_msg_queue = false
  -- fixed size queue of logger messages
  self._msg_queue = nil
  -- vertical layout of log messages
  self.v_layout = wtk.vertical_layout.new(10, colors.dark_blue)
  self.gui:add_child(self.v_layout, 0, 98)
end)

function vlogger.window:initialize_msg_queue(buffer_size)
  buffer_size = buffer_size or vlogger.default_buffer_size
  self._msg_queue = circular_buffer(buffer_size)
  self._initialized_msg_queue = true
end

-- helper method that replaces the base show method to lazily initialise buffer size
--  and show the window at the same time (buffer size is ignored if already initialized)
function vlogger.window:show(buffer_size)
  if not self._initialized_msg_queue then
    self:initialize_msg_queue(buffer_size)
  end
  debug_window.show(self)
end

-- push a log_msg lm to the visual log
-- caveat: the queue has a fixed size of messages rather than lines
--  so when the queue is full, full multiline messages will pop out although
--  in a normal console log, we would expect the lines to go out of view 1 by 1
function vlogger.window:push_msg(lm)
  local has_replaced = self._msg_queue:push(logging.log_msg(lm.level, lm.category, lm.text))

  self:_on_msg_pushed(lm)
  if has_replaced then
    self:_on_msg_popped()
  end
end

-- add a new label to the vertical layout
function vlogger.window:_on_msg_pushed(lm)
  local wrapped_text = wwrap(lm.text, 32)
  local log_label = wtk.label.new(wrapped_text, colors.white)
  self.v_layout:add_child(log_label)
end

-- remove the oldest label of the vertical layout
function vlogger.window:_on_msg_popped()
  assert(#self.v_layout.children >= 1, "vlogger.window:_on_msg_popped: no children in window.v_layout")
  self.v_layout:remove_child(self.v_layout.children[1])
end

local vlog_stream = derived_singleton(logging.log_stream)
vlogger.vlog_stream = vlog_stream

function vlog_stream:on_log(lm)
  vlogger.window:push_msg(lm)
end

return vlogger

--#endif
