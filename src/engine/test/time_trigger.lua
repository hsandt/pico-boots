-- time trigger struct
local time_trigger = new_struct()

-- non-member parameters
-- time            float time to wait before running callback after last trigger (in seconds by default, in frames if use_frame_unit is true)
-- use_frame_unit  bool  if true, count the time in frames instead of seconds
-- members
-- frames          int   number of frames to wait before running callback after last trigger (defined from float time in s)
-- fps             int   fps of the running application (only needed if use_frame_unit is false)
function time_trigger:init(time, use_frame_unit, fps)
  if use_frame_unit then
    self.frames = time
  else
    self.frames = flr(time * fps)
  end
end

--#if tostring
function time_trigger:_tostring()
  return "time_trigger("..self.frames..")"
end
--#endif

-- return true if the trigger condition is verified in this context
-- else return false
-- elapsed_frames     int   number of frames elapsed since the last trigger
function time_trigger:check(elapsed_frames)
  return elapsed_frames >= self.frames
end

-- helper triggers (accessed by reference, make sure not to modify them!)
function time_trigger.immediate()
  return time_trigger(0, true)
end

return time_trigger
