local volume = {}

-- decrease volume for all tracks between `from` and `to` by `decrease_value`
-- use this to reduce the volume of music while keeping it active
--  so you can restore volume later (with a cartridge reload) without interruption
function volume.decrease_volume_for_track_range(from, to, decrease_value)
  for track = from, to do
    volume.decrease_volume_for_track(track, decrease_value)
  end
end

-- decrease volume for sound effect #track by `decrease_value`
function volume.decrease_volume_for_track(track, decrease_value)
  for i = 0, 31 do
    -- 32 sounds per track
    volume.decrease_volume_for_sound(track, i, decrease_value)
  end
end

-- decrease volume for note #note (index starting at 0) of sound effect #track by `decrease_value`
function volume.decrease_volume_for_sound(track, note, decrease_value)
  -- https://pico-8.fandom.com/wiki/Memory > Sound effects
  -- sound effects memory starts at 0x3200
  -- a track takes 68 bytes
  -- a sound takes 2 bytes, and volume is located in 2nd byte
  local note_higher_byte_addr = 0x3200 + 68 * track + 2 * note + 1
  local new_higher_byte = volume.compute_sound_higher_byte_with_decreased_volume(peek(note_higher_byte_addr), decrease_value)
  poke(note_higher_byte_addr, new_higher_byte)
end

-- return higher byte of sound in memory after modifying volume bits so that
--  the volume is decreased by `decrease_value` (clamped to 0)
function volume.compute_sound_higher_byte_with_decreased_volume(higher_byte, decrease_value)
  -- https://pico-8.fandom.com/wiki/Memory > Sound effects
  -- the higher byte is compounded like this:
  -- Higher bit          Lower bit
  -- c  e   e   e   v   v   v   w
  -- volume is contained in the 3 'v' bits, under mask 0b00001110 = 0xe = 14

  -- first, we extract volume (mask + shift right by 1 bit to cover offset of 'w')
  -- we use band instead of & to be compatible with picotool and busted,
  --  but instead of >> 1 we can divide by 0b10 = 2 instead of using shr
  -- second, decrease volume down to 0
  local volume = max(0, band(higher_byte, 14) / 2 - decrease_value)

  -- third, clear the volume bits in the temp higher byte
  --  by applying complementary mask
  -- fourth, re-add decremented volume shifted back by 1 to the left (* 0b10 = 2)
  return bor(band(higher_byte, bnot(14)), volume * 2)
end

return volume
