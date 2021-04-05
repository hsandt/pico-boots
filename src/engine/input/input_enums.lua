button_ids = {
  left = 0,
  right = 1,
  up = 2,
  down = 3,
  o = 4,
  x = 5
}

btn_states = {
  released = 0,
  just_pressed = 1,
  pressed = 2,
  just_released = 3
}

--#if itest
input_modes = {
  native = 0,     -- use pico8 input (or pico8api for utests)
  simulated = 1   -- use hijacking simulated input
}
--#endif
