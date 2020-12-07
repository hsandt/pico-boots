require("engine/test/bustedhelper")
local volume = require("engine/audio/volume")

describe('decrease_volume_for_track_range', function ()

  setup(function ()
    stub(volume, "decrease_volume_for_track")
  end)

  teardown(function ()
    volume.decrease_volume_for_track:revert()
  end)

  it('should call decrease_volume_for_track for all tracks in passed range', function ()
    volume.decrease_volume_for_track_range(4, 6, 2)
    assert.spy(volume.decrease_volume_for_track).was_called(3)
    assert.spy(volume.decrease_volume_for_track).was_called_with(4, 2)
    assert.spy(volume.decrease_volume_for_track).was_called_with(5, 2)
    assert.spy(volume.decrease_volume_for_track).was_called_with(6, 2)
  end)

end)

describe('decrease_volume_for_track', function ()

  setup(function ()
    stub(volume, "decrease_volume_for_sound")
  end)

  teardown(function ()
    volume.decrease_volume_for_sound:revert()
  end)

  it('should call decrease_volume_for_sound for all sounds in passed track', function ()
    volume.decrease_volume_for_track(4, 2)
    assert.spy(volume.decrease_volume_for_sound).was_called(32)
    for i = 0, 31 do
      assert.spy(volume.decrease_volume_for_sound).was_called_with(4, i, 2)
    end
  end)

end)

describe('decrease_volume_for_sound', function ()

  setup(function ()
    stub(volume, "compute_sound_higher_byte_with_decreased_volume", function (value, decrease_value)
      -- simplified example of decrease for testing
      return value - decrease_value
    end)
  end)

  teardown(function ()
    volume.compute_sound_higher_byte_with_decreased_volume:revert()
  end)

  it('should replace byte at 0x3200 + 68 * track + 2 * note + 1 with value returned by compute_sound_higher_byte_with_decreased_volume', function ()
    local addr = 0x3200 + 68 * 4 + 2 * 10 + 1
    poke(addr, 7)
    volume.decrease_volume_for_sound(4, 10, 2)
    assert.are_equal(5, peek(addr))
  end)

end)

describe('compute_sound_higher_byte_with_decreased_volume', function ()

  it('0b11110001 with volume decrease 1 -> 0b11110001 (clamping applies)', function ()
    -- 0b11110001 = 0xf1
    assert.are_equal(0xf1, volume.compute_sound_higher_byte_with_decreased_volume(0xf1, 1))
  end)

  it('0b11111111 with volume decrease 1 -> 0b11111101', function ()
    -- 0b11111111 = 0xff
    -- 0b11111101 = 0xfd
    assert.are_equal(0xfd, volume.compute_sound_higher_byte_with_decreased_volume(0xff, 1))
  end)

end)
