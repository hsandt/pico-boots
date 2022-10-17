require("engine/test/bustedhelper")  -- no specific cartridge, so just use the engine version
local ui_animation = require("engine/ui/ui_animation")

local coroutine_runner = require("engine/application/coroutine_runner")

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

  describe('move_drawables_on_coord_async', function ()

    local corunner

    before_each(function ()
      corunner = coroutine_runner()
    end)

    it('should set coordinate X of each drawable preserving relative offsets', function ()
      local drawable1 = {position = vector(-1, -2)}
      local drawable2 = {position = vector(-4, -7)} -- relative position is (-3, -5)
      corunner:start_coroutine(ui_animation.move_drawables_on_coord_async, 'x', {drawable1, drawable2}, nil, 0, 10, 20)

      -- advance 1 frame, so reach x = 1 * 10/20 = 0.5 for drawable 1,
      --  and since we passed nil coord_offsets, preserve relative position x of -3 for drawable 2
      --  so it should be at x = -2.5
      corunner:update_coroutines()
      assert.are_equal(0.5, drawable1.position.x)
      assert.are_equal(-2.5, drawable2.position.x)

      -- advance 1 more frame, so reach x = 2 * 10/20 = 1 and -2 resp.
      corunner:update_coroutines()
      assert.are_equal(1, drawable1.position.x)
      assert.are_equal(-2, drawable2.position.x)

      for i = 3, 20 do
        corunner:update_coroutines()
      end

      -- advance remaining frames and reach b = 10 and 7 resp.
      assert.are_equal(10, drawable1.position.x)
      assert.are_equal(7, drawable2.position.x)
    end)

    it('should set coordinate X of each drawable using custom relative offsets (even for first drawable)', function ()
      local drawable1 = {position = vector(-1, -2)}
      local drawable2 = {position = vector(-4, -7)} -- relative position is (-3, -5)
      corunner:start_coroutine(ui_animation.move_drawables_on_coord_async, 'x', {drawable1, drawable2}, {10, -10}, 0, 10, 20)

      -- advance 1 frame, so reach x = 1 * 10/20 = 0.5 for drawable 1,
      --  and since we passed nil coord_offsets, preserve relative position x of -3 for drawable 2
      --  so it should be at x = -2.5
      corunner:update_coroutines()
      assert.are_equal(10.5, drawable1.position.x)
      assert.are_equal(-9.5, drawable2.position.x)

      -- advance 1 more frame, so reach x = 2 * 10/20 = 1 and -2 resp.
      corunner:update_coroutines()
      assert.are_equal(11, drawable1.position.x)
      assert.are_equal(-9, drawable2.position.x)

      for i = 3, 20 do
        corunner:update_coroutines()
      end

      -- advance remaining frames and reach b = 10 and 7 resp.
      assert.are_equal(20, drawable1.position.x)
      assert.are_equal(0, drawable2.position.x)
    end)

  end)

end)
