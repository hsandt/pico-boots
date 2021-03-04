-- module handling player input (keyboard and mouse)

-- mode                    input_modes                      current input mode
-- mouse_active            bool                             true iff mouse input is handled / cursor is shown
-- simulated_buttons_down  {int: {button_ids: bool}}        table of static button states, per player index
--                                                          true means down, false means up
--                                                          (simulated mode only)
-- players_btn_states      {int: {button_ids: btn_states}}  table of dynamic button states, per player index
--                                                          (updated from btn() or simulated_buttons_down each frame)
local input = singleton(function (self)
  self.mode = input_modes.native
  self.mouse_active = false

  self.simulated_buttons_down = {}

  -- fill simulated_buttons_down with false values
  -- compressed form equivalent to:
  -- simulated_buttons_down = {
  --   [0] = {
  --     [button_ids.left] = false,
  --     [button_ids.right] = false,
  --     [button_ids.up] = false,
  --     [button_ids.down] = false,
  --     [button_ids.o] = false,
  --     [button_ids.x] = false
  --   },
  --   [1] = {
  --     [button_ids.left] = false,
  --     [button_ids.right] = false,
  --     [button_ids.up] = false,
  --     [button_ids.down] = false,
  --     [button_ids.o] = false,
  --     [button_ids.x] = false
  --   }
  -- }
  for i = 0, 1 do
    local tab = {}
    for i = 0, 5 do
      tab[i] = false
    end
    self.simulated_buttons_down[i] = tab
  end

  self.players_btn_states = {}

  -- compressed form equivalent to:
  -- self.players_btn_states = {
  --   [0] = {
  --     [button_ids.left] = btn_states.released,
  --     [button_ids.right] = btn_states.released,
  --     [button_ids.up] = btn_states.released,
  --     [button_ids.down] = btn_states.released,
  --     [button_ids.o] = btn_states.released,
  --     [button_ids.x] = btn_states.released
  --   },
  --   [1] = {
  --     [button_ids.left] = btn_states.released,
  --     [button_ids.right] = btn_states.released,
  --     [button_ids.up] = btn_states.released,
  --     [button_ids.down] = btn_states.released,
  --     [button_ids.o] = btn_states.released,
  --     [button_ids.x] = btn_states.released
  --   }
  -- }
  for i = 0, 1 do
    local tab = {}
    for i = 0, 5 do
      tab[i] = btn_states.released
    end
    self.players_btn_states[i] = tab
  end
end)

local mouse_devkit_address = 0x5f2d
local cursor_x_stat = 32
local cursor_y_stat = 33

--#if mouse

-- activate mouse devkit
-- to visualize the mouse, you still need to:
-- 1. add cursor sprite to spritesheet (edit data and save)
-- 2. set cursor sprite with ui:set_cursor_sprite_data (e.g. in your app.on_start)
-- 3. call mouse:render() each frame (e.g. in your app.on_render)
function input:toggle_mouse(active)
  if active == nil then
    -- no argument => reverse value
    active = not self.mouse_active
  end
  value = active and 1 or 0
  self.mouse_active = active
  poke(mouse_devkit_address, value)
end

-- return the current cursor position
function input.get_cursor_position()
  return vector(stat(cursor_x_stat), stat(cursor_y_stat))
end

--#endif

-- return a button state for player id (0 by default)
function input:get_button_state(button_id, player_id)
  assert(type(button_id) == "number" and button_id >= 0 and button_id < 6, "input:get_button_state: button_id ("..tostr(button_id)..") is not between 0 and 5")
  player_id = player_id or 0
  return self.players_btn_states[player_id][button_id]
end

-- return true if button is released or just released for player id (0 by default)
function input:is_up(button_id, player_id)
  local button_state = self:get_button_state(button_id, player_id)
  return button_state == btn_states.released or button_state == btn_states.just_released
end

-- return true if button is pressed or just pressed for player id (0 by default)
function input:is_down(button_id, player_id)
  return not self:is_up(button_id, player_id)
end

-- return true if button is just released for player id (0 by default)
function input:is_just_released(button_id, player_id)
  local button_state = self:get_button_state(button_id, player_id)
  return button_state == btn_states.just_released
end

-- return true if button is just pressed for player id (0 by default)
function input:is_just_pressed(button_id, player_id)
  local button_state = self:get_button_state(button_id, player_id)
  return button_state == btn_states.just_pressed
end

-- update button states for each player based on previous and current button states
function input:process_players_inputs()
  for player_id = 0, 1 do
    self:process_player_inputs(player_id)
  end
end

-- update button states for a specific player based on previous and current button states
function input:process_player_inputs(player_id)
  local player_btn_states = self.players_btn_states[player_id]
  for button_id, _ in pairs(player_btn_states) do

    -- edge case handling: in general, btnp should always return true when just pressed, but the reverse is not true because pico8
    --  has a repeat input feature, that we are not reproducing
    -- however, in some cases PICO-8 may miss process_player_inputs on some frames (e.g. when using debug step)
    --  so we will reach an invalid state where button was released, is not down, but we missed the moment it was just pressed
    -- in this case, just reset the button state to being pressed, so compute_next_button_state will not return
    --  just_pressed, which would cause the game to detect a press when there is none (e.g. pressing X
    --  just when leaving the debug step mode in gameapp)
    -- an alternative is to set button state to just_pressed whenever btnp() returns true, and pressed
    --  if only btn() returns true, but then compute_next_button_state would need to check for input_modes.native
    --  and be less generic
    if self.mode == input_modes.native and self:is_up(button_id, player_id) and btn(button_id, player_id) and not btnp(button_id, player_id) then
      -- player_btn_states[button_id] = btn_states.pressed
    end

    player_btn_states[button_id] = self:compute_next_button_state(player_btn_states[button_id], self:btn_proxy(button_id, player_id))
  end
end

-- return true if the button is considered down by the current low-level i/o: native or simulated
function input:btn_proxy(button_id, player_id)
  if self.mode == input_modes.native then
    return btn(button_id, player_id)
  else  -- self.mode == input_modes.simulated
    player_id = player_id or 0
    return self.simulated_buttons_down[player_id][button_id]
  end
end

-- return the next button state of a button based on its previous dynamic state (stored) and current static state (pico8 input)
function input:compute_next_button_state(previous_button_state, is_down)
  if previous_button_state == btn_states.released then
    if is_down then
      return btn_states.just_pressed
    end
  elseif previous_button_state == btn_states.just_pressed then
    if is_down then
      return btn_states.pressed
    else
      return btn_states.just_released
    end
  elseif previous_button_state == btn_states.pressed then
    if not is_down then
      return btn_states.just_released
    end
  else  -- previous_button_state == btn_states.just_released
    if is_down then
      return btn_states.just_pressed
    else
      return btn_states.released
    end
  end

  -- no change detected
  return previous_button_state
end

return input
