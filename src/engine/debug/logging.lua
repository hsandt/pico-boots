--#if log

require("engine/core/class")
require("engine/core/helper")
require("engine/test/assertions")

local logging = {
  level = {
    info = 1,     -- show all messages
    warning = 2,  -- show warnings and errors
    error = 3,    -- show errors only
    none = 4,     -- show nothing
  }
}

-- log message struct
local log_msg = new_struct()
logging.log_msg = log_msg

-- level     logging.level  importance level of the message
-- text      string         textual content
-- category  string         category in which the message belongs to (see logger.active_categories)
function log_msg:_init(level, category, text)
  self.level = level
  self.category = category
  self.text = text
end

--#if log
function log_msg:_tostring()
  return "log_msg("..joinstr(", ", self.level, dump(self.category), dump(self.text))..")"
end
--#endif

function logging.compound_message(lm)
  if lm.level == logging.level.warning then
    prefix = "warning: "
  elseif lm.level == logging.level.error then
    prefix = "error: "
  else
    prefix = ""
  end
  return "["..lm.category.."] "..prefix..lm.text
end

-- log stream abstract base singleton. derive to make a custom logger
-- active      boolean                       is the stream active? is false, all output is muted
-- log         function(self, lm: log_msg)   external callback on log message received
-- on_log      function(self, lm: log_msg)   internal callback on log message received, only called if active
local log_stream = singleton(function (self)
  self.active = true
end)
logging.log_stream = log_stream

function log_stream:log(lm)
  if self.active then
    self:on_log(lm)
  end
end

-- abstract
-- function log_stream:on_log()
-- end


-- console log
console_log_stream = derived_singleton(log_stream)
logging.console_log_stream = console_log_stream

function console_log_stream:on_log(lm)
  printh(logging.compound_message(lm))
end


-- file log
file_log_stream = derived_singleton(log_stream, function (self)
  self.file_prefix = "game"  -- override this to distinguish logs between games and versions
end)
logging.file_log_stream = file_log_stream

function file_log_stream:clear()
  -- clear file by printing nothing while overwriting content
  -- note: this will print an empty line at the beginning of the file
  printh("", self.file_prefix.."_log", true)
end

function file_log_stream:on_log(lm)
  -- pico8 will add .p8l extension
  printh(logging.compound_message(lm), self.file_prefix.."_log")
end


local logger = singleton(function (self)
  self.active_categories = {
    default = true,
    flow = true,
    log = true,
    player = true,
    render = true,
    ui = true,
    codetuner = true,
    itest = true,
    -- trace is considered a category, not a level, so we can toggle it independently from the rest
    trace = false
  }
  self.current_level = logging.level.info
  self.dump_max_recursion_level = 5

  -- streams to log to
  self._streams = {}
end)

-- export
logging.logger = logger

-- set all categories active flag to false to mute logging
function logger:deactivate_all_categories()
  for category, _ in pairs(self.active_categories) do
    self.active_categories[category] = false
  end
end

-- register a stream toward which logging will be sent (console, file...)
function logger:register_stream(stream)
  assert(stream, "logger:register_stream: passed stream is nil")
  assert(type(stream.on_log) == "function" or type(stream.on_log) == "table" and getmetatable(stream.on_log).__call, "logger:register_stream: passed stream is invalid: on_log member is nil or not a callable")
--#if log
  if contains(self._streams, stream) then
    warn("logger:register_stream: passed stream already registered, ignoring it", 'log')
    return
  end
--#endif
  add(self._streams, stream)
end

-- level     logging.level
-- category  str
-- content   str
function logger:_generic_log(level, category, content)
  category = category or "default"
  if logger.active_categories[category] and logger.current_level <= level then
    local lm = log_msg(level, category, stringify(content))
    for stream in all(self._streams) do
      stream:log(lm)
    end
  end
end

-- print an info content to the console in a category string
function log(content, category)
  logger:_generic_log(logging.level.info, category, content)
end

-- print a warning content to the console in a category string
function warn(content, category)
  logger:_generic_log(logging.level.warning, category, content)
end

-- print an error content to the console in a category string
function err(content, category)
  logger:_generic_log(logging.level.error, category, content)
end

return logging

--#endif
