local sound = {}

-- play sfx on channel, only if this channel is free
-- note that unlike sfx(), you *must* pass a channel
function sound.play_low_priority_sfx(n, channel, offset)
  -- stat(16 + channel) returns the index of the SFX played on channel #channel (0-3),
  --  -1 if no SFX is played
  if stat(16 + channel) == -1 then
    sfx(n, channel, offset)
  end
end

return sound
