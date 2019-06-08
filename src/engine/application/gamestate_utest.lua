local gamestate = require("engine/application/gamestate")

describe('gamestate', function ()

  describe('(dummy derived gamestate)', function ()

    local dummy_gamestate = derived_class(gamestate)

    function dummy_gamestate._init()
    end

    local state

    before_each(function ()
      state = dummy_gamestate()
    end)

    it('on_enter should do nothing', function ()
      assert.has_no_errors(function ()
        state:on_enter()
      end)
    end)

    it('on_exit should do nothing', function ()
      assert.has_no_errors(function ()
        state:on_exit()
      end)
    end)

    it('update should do nothing', function ()
      assert.has_no_errors(function ()
        state:update()
      end)
    end)

    it('render should do nothing', function ()
      assert.has_no_errors(function ()
        state:render()
      end)
    end)

  end)

end)
