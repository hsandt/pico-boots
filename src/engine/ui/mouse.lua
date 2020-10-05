local input = require("engine/input/input")

local mouse = {
  -- will be set in set_cursor_sprite_data
  -- cursor_sprite_data = nil
}

--#if mouse

-- injection function: call it from game to set the sprite data
-- for the mouse cursor. this avoids accessing game data
-- from an engine script
-- cursor_sprite_data  sprite_data
function mouse:set_cursor_sprite_data(cursor_sprite_data)
  self.cursor_sprite_data = cursor_sprite_data
end

-- render mouse cursor at system cursor position
function mouse:render()
  if input.mouse_active and self.cursor_sprite_data then
    camera(0, 0)
    local cursor_position = input.get_cursor_position()
    self.cursor_sprite_data:render(cursor_position)
  end
end

--#endif

return mouse
