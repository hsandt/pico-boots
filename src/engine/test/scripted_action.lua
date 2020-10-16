-- scripted action struct (but we use class because comparing functions only work by reference)
local scripted_action = new_class()

-- parameters
-- trigger           trigger             trigger that will run the callback
-- callback          function            callback called on trigger
-- name              string | nil        optional name for debugging
function scripted_action:init(trigger, callback, name)
  self.trigger = trigger
  self.callback = callback
  self.name = name or "unnamed"
end

--#if tostring
function scripted_action:_tostring()
  return "[scripted_action ".."'"..self.name.."' ".."@ "..self.trigger.."]"
end
--#endif

return scripted_action
