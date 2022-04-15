require("engine/test/bustedhelper")  -- no specific cartridge, so just use the engine version
local ui_animation = require("engine/ui/ui_animation")

describe('ui_animation', function ()

  describe('lerp', function ()

    it('(4, 8, 0) => 0', function ()
      assert.are_equal(4, ui_animation.lerp(4, 8, 0))
    end)

    it('(4, 8, 0.5) => 6 (1/2 of the way)', function ()
      assert.are_equal(6, ui_animation.lerp(4, 8, 0.5))
    end)

    it('(4, 8, 1) => 8', function ()
      assert.are_equal(8, ui_animation.lerp(4, 8, 1))
    end)

    -- unclamped!
    it('(4, 8, 2) => 12', function ()
      assert.are_equal(12, ui_animation.lerp(4, 8, 2))
    end)

  end)

  describe('lerp_clamped', function ()

    it('(4, 8, 0) => 0', function ()
      assert.are_equal(4, ui_animation.lerp_clamped(4, 8, 0))
    end)

    it('(4, 8, 0.5) => 6 (1/2 of the way)', function ()
      assert.are_equal(6, ui_animation.lerp_clamped(4, 8, 0.5))
    end)

    it('(4, 8, 1) => 8', function ()
      assert.are_equal(8, ui_animation.lerp_clamped(4, 8, 1))
    end)

    -- clamped up
    it('(4, 8, 2) => 8', function ()
      assert.are_equal(8, ui_animation.lerp_clamped(4, 8, 2))
    end)

    -- clamped down
    it('(4, 8, -1) => 4', function ()
      assert.are_equal(4, ui_animation.lerp_clamped(4, 8, -1))
    end)

    -- clamped even with a > b
    it('(8, 4, 2) => 8', function ()
      assert.are_equal(8, ui_animation.lerp_clamped(4, 8, 2))
    end)

  end)

  describe('ease_in', function ()

    it('(4, 8, 0) => 0', function ()
      assert.are_equal(4, ui_animation.ease_in(4, 8, 0))
    end)

    it('(4, 8, 0.5) => 5 (1/4 of the way)', function ()
      assert.are_equal(5, ui_animation.ease_in(4, 8, 0.5))
    end)

    it('(4, 8, 1) => 8', function ()
      assert.are_equal(8, ui_animation.ease_in(4, 8, 1))
    end)

  end)

  describe('ease_out', function ()

    it('(4, 8, 0) => 0', function ()
      assert.are_equal(4, ui_animation.ease_out(4, 8, 0))
    end)

    it('(4, 8, 0.5) => 7 (3/4 of the way)', function ()
      assert.are_equal(7, ui_animation.ease_out(4, 8, 0.5))
    end)

    it('(4, 8, 1) => 8', function ()
      assert.are_equal(8, ui_animation.ease_out(4, 8, 1))
    end)

  end)

  describe('ease_in_out', function ()

    it('(4, 8, 0) => 0', function ()
      assert.are_equal(4, ui_animation.ease_in_out(4, 8, 0))
    end)

    it('(4, 8, 0.25) => 4.5 (1/4 of the 1st half ie 1/8)', function ()
      assert.are_equal(4.5, ui_animation.ease_in_out(4, 8, 0.25))
    end)

    it('(4, 8, 0.5) => 6 (1/2 of the way)', function ()
      assert.are_equal(6, ui_animation.ease_in_out(4, 8, 0.5))
    end)

    it('(4, 8, 0.75) => 7.5 (3/4 of the 2nd half ie 7/8)', function ()
      assert.are_equal(7.5, ui_animation.ease_in_out(4, 8, 0.75))
    end)

    it('(4, 8, 1) => 8', function ()
      assert.are_equal(8, ui_animation.ease_in_out(4, 8, 1))
    end)

  end)

end)
