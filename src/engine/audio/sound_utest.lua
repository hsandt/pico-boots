require("engine/test/bustedhelper")
local sound = require("engine/audio/sound")

describe('sound', function ()

  describe('play_low_priority_sfx', function ()

    local channel_sfx = {-1, 0, 1, 2}

    setup(function ()
      stub(_G, "stat", function (n)
        return channel_sfx[n - 15]
      end)
      stub(_G, "sfx")
    end)

    teardown(function ()
      stat:revert()
      sfx:revert()
    end)

    after_each(function ()
      stat:clear()
      sfx:clear()
    end)

    it('should play sfx when nothing in played on target channel', function ()
      sound.play_low_priority_sfx(5, 0, 10)
      assert.spy(sfx).was_called(1)
      assert.spy(sfx).was_called_with(5, 0, 10)
    end)

    it('should not play sfx when something in played on target channel', function ()
      sound.play_low_priority_sfx(5, 1, 10)
      assert.spy(sfx).was_not_called()
    end)

  end)

end)
