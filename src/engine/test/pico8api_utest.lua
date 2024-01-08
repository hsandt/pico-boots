require("engine/test/bustedhelper")

describe('pico8api', function ()

  describe('camera', function ()

    after_each(function ()
      camera()
    end)

    it('should the camera to a floored pixel-perfect position', function ()
      camera(5.1, -11.5)
      assert.are_same({5, -12}, {pico8.camera_x, pico8.camera_y})
    end)

    it('should reset the camera with no arguments', function ()
      camera(5.1, -11.5)
      camera()
      assert.are_same({0, 0}, {pico8.camera_x, pico8.camera_y})
    end)

  end)

  describe('clip', function ()

    after_each(function ()
      clip()
    end)

    it('should set clip to floored pixel-perfect (x, y, w, h)', function ()
      clip(5.7, 12.4, 24.2, 48.1)
      assert.are_same({5, 12, 24, 48}, pico8.clip)
    end)

    it('should reset the clip to fullscreen when no argument is passed', function ()
      clip()
      assert.are_same({0, 0, 128, 128}, pico8.clip)
    end)

    it('should return the previous state as 4 values (x, y, w, h) on reset (no arguments)', function ()
      clip(40, 50, 20, 30)
      local previous_state = {clip()}
      assert.are_same({40, 50, 20, 30}, previous_state)
    end)

  end)

  describe('cls', function ()

    it('should reset the clip to fullscreen', function ()
      cls()
      assert.are_same({0, 0, 128, 128}, pico8.clip)
    end)

  end)

  describe('pset', function ()

    it('should set the current color', function ()
      pset(5, 8, 7)
      assert.are_equal(7, pico8.color)
    end)

  end)

  describe('pget', function ()

    it('should return 0 (no simulation)', function ()
      assert.are_equal(0, pget(8, 5))
    end)

  end)

  describe('color', function ()

    it('should set the current color', function ()
      color(9)
      assert.are_equal(9, pico8.color)
    end)

    it('should set the current color (with modulo 16)', function ()
      color(17)
      assert.are_equal(1, pico8.color)
    end)

    it('should reset the current color with no arguments', function ()
      color()
      assert.are_equal(0, pico8.color)
    end)

  end)

  describe('tonum', function ()

    it('should return the number corresponding to a number', function ()
      assert.are_equal(-25.34, tonum(-25.34))
    end)

    it('should return the positive number corresponding to a string', function ()
      assert.are_equal(25, tonum("25"))
    end)

    it('should return the negative number corresponding to a string (not fractional power of 2)', function ()
      assert.are_equal(-25.34, tonum("-25.34"))
    end)

    -- this one is for native Lua only: PICO-8 itself doesn't pass it
    -- because tonum fails on negative number strings of 0x0000.0001!
    it('should return the negative number corresponding to a string (fractional power of 2)', function ()
      assert.are_equal(-25.25, tonum("-25.25"))
    end)

  end)

  describe('to_fixed_point', function ()

    it('0 => 0', function ()
      assert.are_equal(0, to_fixed_point(0))
    end)

    it('PICO-8-compatible integer => same integer', function ()
      assert.are_equal(0x1234, to_fixed_point(0x1234))
    end)

    it('PICO-8-compatible number => same number', function ()
      assert.are_equal(0x1234.5, to_fixed_point(0x1234.5))
    end)

    it('PICO-8-compatible number => same number', function ()
      assert.are_equal(0x1234.5678, to_fixed_point(0x1234.5678))
    end)

    it('number more precise than in PICO-8 => number cut to PICO-8 precision', function ()
      assert.are_equal(0x1234.5678, to_fixed_point(0x1234.56789))
    end)

    it('negative number more precise than in PICO-8 => number cut to PICO-8 precision', function ()
      assert.are_equal(-0x1234.5678, to_fixed_point(-0x1234.56789))
    end)

  end)

  describe('tostr', function ()
    it('nothing => ""', function ()
      assert.are_equal("", tostr())
    end)
    -- this used to return [nil], differing from pico8 0.1
    --  (which would return "[no value]") and pico8 0.2.0 (which would return nil),
    --  but since pico8 0.2.2, both our implementation and pico8 return ""
    --  when no argument is passed (nothing, not nil)
    it('empty function return => ""', function ()
      function f() end
      assert.are_equal("", tostr(f()))
    end)
    it('nil => "[nil]"', function ()
      assert.are_equal("[nil]", tostr(nil))
    end)
    it('"string" => "string"', function ()
      assert.are_equal("string", tostr("string"))
    end)
    it('true => "true"', function ()
      assert.are_equal("true", tostr(true))
    end)
    it('false => "false"', function ()
      assert.are_equal("false", tostr(false))
    end)
    it('56 => "56"', function ()
      assert.are_equal("56", tostr(56))
    end)
    it('56.2 => "56.2"', function ()
      assert.are_equal("56.2", tostr(56.2))
    end)
    it('0x58cb.fd85, hex: true => "0x58cb.fd85"', function ()
      assert.are_equal("0x58cb.fd85", tostr(0x58cb.fd85, true))
    end)
    -- this one is only useful to test robustness with native Lua:
    --  in PICO-8, floats have 16:16 fixed point precision,
    --  so they can never get more than 4 hex figures after the point
    -- with busted, we need to cut the extra hex figures to avoid
    --  error "number (local 'val') has no integer representation"
    --  when applying binary operations
    it('0x58cb.fd8524 => "0x58cb.fd85" (hex)', function ()
      assert.are_equal("0x58cb.fd85", tostr(0x58cb.fd8524, true))
    end)

    -- since PICO-8 0.2.0, table and function addresses can be obtained via tostr/tostring
    -- but only when passing hex: true
    -- interestingly, it doesn't do it for coroutines (type "thread"),
    -- but you can still use tostring if you need to see their address

    it('{}, hex: false => "[table]"', function ()
      assert.are_equal("[table]", tostr({}))
    end)
    it('function, hex: false => "[function]"', function ()
      local f = function ()
      end
      assert.are_equal("[function]", tostr(f))
    end)

    it('{}, hex: true => "table: 0x..."', function ()
      local tab = {}
      assert.are_equal(tostring(tab), tostr(tab, true))
    end)
    it('function, hex: true => "function: 0x..."', function ()
      local f = function () end
      assert.are_equal(tostring(f), tostr(f, true))
    end)

    it('thread, hex: false => "[thread]"', function ()
      local f = function () end
      local c = cocreate(f)
      assert.are_equal("[thread]", tostr(c))
    end)

    it('thread, hex: true => "[thread]"', function ()
      local f = function () end
      local c = cocreate(f)
      assert.are_equal("[thread]", tostr(c))
    end)

  end)

  describe('(testing color)', function ()

    after_each(function ()
      color()
    end)

    describe('api.print', function ()

      it('should set the color if passed', function ()
        api.print("hello", 45, 78, 7)
        assert.are_equal(7, pico8.color)
      end)

      it('should preserve the color if not passed', function ()
        color(5)
        api.print("hello", 45, 78)
        assert.are_equal(5, pico8.color)
      end)

      it('should handle the 2nd argument as color if there are no further arguments', function ()
        color(5)
        api.print("hello", 7)
        assert.are_equal(7, pico8.color)
      end)

      it('should still handle the 2nd argument as x and 4th as color if there is even nil as 3rd argument', function ()
        color(5)
        api.print("hello", 45, nil, 7)
        assert.are_equal(7, pico8.color)
      end)

    end)

    describe('rect', function ()

      it('should set the color if passed', function ()
        rect(1, 2, 3, 4, 7)
        assert.are_equal(7, pico8.color)
      end)

      it('should preserve the color if not passed', function ()
        color(5)
        rect(1, 2, 3, 4)
        assert.are_equal(5, pico8.color)
      end)

    end)

    describe('rectfill', function ()

      it('should set the color if passed', function ()
        rectfill(1, 2, 3, 4, 7)
        assert.are_equal(7, pico8.color)
      end)

      it('should preserve the color if not passed', function ()
        color(5)
        rectfill(1, 2, 3, 4)
        assert.are_equal(5, pico8.color)
      end)

    end)

    describe('circ', function ()

      it('should set the color if passed', function ()
        circ(1, 2, 10, 7)
        assert.are_equal(7, pico8.color)
      end)

      it('should preserve the color if not passed', function ()
        color(5)
        circ(1, 2, 3)
        assert.are_equal(5, pico8.color)
      end)

    end)

    describe('circfill', function ()

      it('should set the color if passed', function ()
        circfill(1, 2, 10, 7)
        assert.are_equal(7, pico8.color)
      end)

      it('should preserve the color if not passed', function ()
        color(5)
        circfill(1, 2, 10)
        assert.are_equal(5, pico8.color)
      end)

    end)

    describe('line', function ()

      it('should set the color if passed', function ()
        line(1, 2, 10, 12, 7)
        assert.are_equal(7, pico8.color)
      end)

      it('should preserve the color if not passed', function ()
        color(5)
        line(1, 2, 10, 12)
        assert.are_equal(5, pico8.color)
      end)

    end)

    describe('pal', function ()

      it('should reset the transparency with no arguments', function ()
        pico8.pal_transparent[1] = true
        pal()
        assert.are_same({[0] = true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false},
          pico8.pal_transparent)
      end)

    end)

    describe('palt', function ()

      it('should set the color to transparent when passing a color and true', function ()
        palt(3, true)
        assert.are_equal(true, pico8.pal_transparent[3])
      end)

      it('should set the color to opaque when passing a color and false', function ()
        palt(3, false)
        assert.are_equal(false, pico8.pal_transparent[3])
      end)

      it('should set transparent colors when only passing a bitmask (low-endian style)', function ()
        -- 0b pattern is not supported by pure Lua, so use hex value: 0b1100110011001100 -> 0xcccc
        palt(0xcccc)
        assert.are_same({[0] = true, true, false, false, true, true, false, false, true, true, false, false, true, true, false, false},
          pico8.pal_transparent)
      end)

      it('should reset the transparency with no arguments', function ()
        palt()
        assert.are_same({[0] = true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false},
          pico8.pal_transparent)
      end)

    end)

  end)

  describe('mget', function ()

    before_each(function ()
      pico8.map[14] = { [27] = 5 }
    end)

    after_each(function ()
      pico8.map[14][27] = 0
    end)

    it('should return the sprite id at a map coordinate', function ()
      assert.are_equal(5, mget(27, 14))
    end)

    it('should return 0 if out of bounds', function ()
      assert.are_equal(0, mget(-1, 15))
    end)

  end)

  describe('mset', function ()

    after_each(function ()
      pico8.map[14] = 0
    end)

    it('should set the sprite id at a map coordinate', function ()
      mset(27, 14, 9)
      assert.are_equal(9, mget(27, 14))
    end)

  end)

  describe('fget', function ()

    before_each(function ()
      pico8.spriteflags[3] = 0xa2
    end)

    after_each(function ()
      pico8.spriteflags[3] = 0
    end)

    it('should return the sprite flags for the passed sprite id', function ()
      assert.are_equal(0xa2, fget(3))
    end)

    it('should return 0 for a sprite id outside [0-255]', function ()
      assert.are_same({0x0, 0x0}, {fget(-1), fget(256)})
    end)

    it('should return if a specific sprite flag is set on a passed sprite id', function ()
      assert.are_same({true, true, true, false}, {fget(3, 1), fget(3, 5), fget(3, 7), fget(3, 6)})
    end)

    it('should return false for unset sprite flag (just to simplify simulation without setup)', function ()
      assert.are_same({false, false, false, false}, {fget(1, 1), fget(2, 5), fget(4, 7), fget(5, 6)})
    end)

    it('should return false for unset sprite flag (just to simplify simulation without setup)', function ()
      assert.are_same({false, false, false, false}, {fget(1, 1), fget(2, 5), fget(4, 7), fget(5, 6)})
    end)

    it('should return false for any flag for a sprite id outside [0-255]', function ()
      assert.are_same({false, false}, {fget(-1, 1), fget(256, 10)})
    end)

  end)

  describe('fset', function ()

    after_each(function ()
      pico8.spriteflags[3] = 0
    end)

    it('should set the sprite flags for the passed sprite id', function ()
      fset(3, 0xa2)
      assert.are_equal(0xa2, fget(3))
    end)

    it('should set a specific sprite flag on a passed sprite id', function ()
      fset(3, 1, false)
      fset(3, 3, true)
      fset(3, 5, true)
      fset(3, 7, true)
      fset(3, 7, false)
      assert.are_same({false, true, true, false, false}, {fget(3, 1), fget(3, 3), fget(3, 5), fget(3, 6), fget(3, 7)})
    end)

  end)

  describe('sget', function ()

    it('should return 0 (no simulation)', function ()
      assert.are_equal(0, sget(3))
    end)

  end)

  describe('music', function ()

    it('should set the current music with defaults', function ()
      music(4, 14, 6)
      assert.are_same({music=4, fadems=14, channel_mask=6}, pico8.current_music)
      music(7)
      assert.are_same({music=7, fadems=0, channel_mask=0}, pico8.current_music)
    end)

    it('should reset the current music with -1', function ()
      music(-1)
      assert.is_nil(pico8.current_music)
    end)

    it('should fallback to music pattern 0 if < -1 is passed', function ()
      music(-2)
      assert.are_same({music=0, fadems=0, channel_mask=0}, pico8.current_music)
    end)

  end)

  describe('(memory setup)', function ()

    before_each(function ()
      pico8.poked_addresses[4] = 0xa2
      pico8.poked_addresses[5] = 0x01
      pico8.poked_addresses[6] = 0x10
      pico8.poked_addresses[7] = 0x01
      pico8.poked_addresses[8] = 0x00
      pico8.poked_addresses[9] = 0x00
      pico8.poked_addresses[10] = 0x00
      pico8.poked_addresses[11] = 0x00
      pico8.poked_addresses[12] = 0x14
      pico8.poked_addresses[13] = 0xde
      pico8.poked_addresses[14] = 0x48
      pico8.poked_addresses[15] = 0x3a
      pico8.poked_addresses[16] = 0xc5
      pico8.poked_addresses[17] = 0x97
      pico8.poked_addresses[18] = 0xb2
      pico8.poked_addresses[19] = 0x01
    end)

    after_each(function ()
      clear_table(pico8.poked_addresses)
    end)

    describe('peek', function ()

      it('should return the memory at the address', function ()
        assert.are_equal(0xa2, peek(4))
      end)

      it('should return 0 if memory has not been poked (to be closer to PICO-8 and avoid nil crashes)', function ()
        assert.are_equal(0x0, peek(20))
      end)

    end)

    describe('poke', function ()

      it('should set the memory at the address', function ()
        poke(4, 0xb3)
        assert.are_equal(0xb3, peek(4))
      end)

    end)

    describe('peek2', function ()

      it('should return the batch memory at the address', function ()
        assert.are_equal(0x01a2, peek2(4))
      end)

    end)

    describe('poke2', function ()

      it('should set the batch memory at the address', function ()
        poke2(4, 0x30b3)
        assert.are_equal(0x30b3, peek2(4))
        assert.are_same({0x30, 0xb3}, {peek(5), peek(4)})
      end)

    end)

    describe('peek4', function ()

      it('should return the batch memory at the address', function ()
        assert.are_equal(0x0110.01a2, peek4(4))
      end)

    end)

    describe('poke4', function ()

      it('should set the batch memory at the address', function ()
        poke4(4, 0x12bc.30b3)
        assert.are_equal(0x12bc.30b3, peek4(4))
        assert.are_same({0x12, 0xbc, 0x30, 0xb3}, {peek(7), peek(6), peek(5), peek(4)})
      end)

    end)

    describe('memcpy', function ()

      it('should copy the memory at the address for length', function ()
        memcpy(8, 4, 4)
        assert.are_equal(0x0110.01a2, peek4(4))
        assert.are_equal(0x0110.01a2, peek4(8))
      end)

      it('should copy the memory at the address for length to address earlier in memory with overlap', function ()
        memcpy(8, 12, 8)
        assert.are_equal(0x01b2.97c5, peek4(16))
        assert.are_equal(0x01b2.97c5, peek4(12))
        assert.are_equal(0x3a48.de14, peek4(8))
      end)

      it('should do nothing if len < 1 or dest_addr == source_addr', function ()
        memcpy(8, 12, 0)
        memcpy(8, 8, 0)
        assert.are_equal(0x0, peek4(8))
      end)

    end)

    describe('memset', function ()

      it('should set the same byte in memory at the address along length', function ()
        memset(8, 0x24, 4)
        assert.are_equal(0x2424.2424, peek4(8))
      end)

      it('should do nothing if len < 1', function ()
        memset(8, 0x24, 0)
        assert.are_equal(0x0, peek4(8))
      end)

    end)

  end)

  describe('rnd', function ()

    it('should return a number between 0 and 1 by default', function ()
      assert.is_true(0 <= rnd())
      assert.is_true(rnd() < 1)
    end)

    it('should return a number between 0 and x (positive)', function ()
      assert.is_true(0 <= rnd(10))
      assert.is_true(rnd() < 10)
    end)

    -- negative input returns a random float from MIN to MAX, but this is undocumented

    -- below: new rnd(array) added in v0.2.0d

    it('should return nil if the table is empty', function ()
      assert.is_nil(rnd({}))
    end)

    it('should return the single table element if of length 1', function ()
      assert.are_equal(146, rnd({146}))
    end)

    -- testing a random function is hard, so stub math.random
    -- with the two extreme cases

    describe('(math.random returns lower bound)', function ()

      setup(function ()
        stub(math, "random", function (upper)
          return 1
        end)
      end)

      teardown(function ()
        math.random:revert()
      end)

      it('should return the first element', function ()
        assert.are_equal(100, rnd({100, 200, 300}))
      end)

    end)

    describe('(math.random returns upper bound)', function ()

      setup(function ()
        stub(math, "random", function (upper)
          return upper
        end)
      end)

      teardown(function ()
        math.random:revert()
      end)

      it('should return the last element', function ()
        assert.are_equal(300, rnd({100, 200, 300}))
      end)

    end)

  end)

  describe('srand', function ()

    local randomseed_stub

    setup(function ()
      randomseed_stub = stub(math, "randomseed")
    end)

    teardown(function ()
      randomseed_stub:revert()
    end)

    after_each(function ()
      randomseed_stub:clear()
    end)

    it('should call math.randomseed', function ()
      srand(0x.425a)
      assert.spy(randomseed_stub).was_called(1)
      assert.spy(randomseed_stub).was_called_with(0x425a)
    end)

  end)

  describe('flr', function ()

    it('should return a floored value', function ()
      assert.are_same({2, 5, -4}, {flr(2), flr(5.5), flr(-3.1)})
    end)

    it('should return 0 by default', function ()
      assert.are_equal(0, flr())
    end)

  end)

  describe('ceil', function ()

    it('should return a ceiled value', function ()
      assert.are_same({-1, 6, -3}, {ceil(-1), ceil(5.5), ceil(-3.1)})
    end)

    it('should return 0 by default', function ()
      assert.are_equal(0, ceil())
    end)

  end)

  describe('sgn', function ()

    it('should return 1 for a positive value', function ()
      assert.are_equal(1, sgn(1.5))
    end)

    it('should return 1 for 0', function ()
      assert.are_equal(1, sgn(0))
    end)

    it('should return -1 for a negative value', function ()
      assert.are_equal(-1, sgn(-1.5))
    end)

  end)

  describe('min', function ()

    it('should return the minimum of two values', function ()
      assert.are_equal(-4, min(-4, 1.5))
      assert.are_equal(1.5, min(5, 1.5))
    end)

    it('should consider nil args as 0 (no args)', function ()
      assert.are_equal(0, min())
    end)

    it('should consider nil args as 0 (1 arg)', function ()
      assert.are_equal(-5, min(-5))
    end)

  end)

  describe('max', function ()

    it('should return the maximum of two values', function ()
      assert.are_equal(1.5, max(-4, 1.5))
    end)

    it('should consider nil args as 0 (no args)', function ()
      assert.are_equal(0, max())
    end)

    it('should consider nil args as 0 (1 arg)', function ()
      assert.are_equal(5, max(5))
    end)

  end)

  describe('mid', function ()

    it('should return the mid of 3 values', function ()
      assert.are_equal(1.5, mid(3, -4, 1.5))
      assert.are_equal(3, mid(3, 5, 1.5))
      assert.are_equal(2, mid(3, 2, 1.5))
    end)

  end)

  describe('cos', function ()

    it('should return 1 by default (0 angle)', function ()
      assert.are_equal(1, cos())
    end)

    it('should return 1 for 0 turn ratio', function ()
      assert.are_equal(1, cos(0))
    end)

    it('should return 0 for 0.25 turn ratio', function ()
      assert.is_true(almost_eq_with_message(0, cos(0.25)))
    end)

    it('should return -1 for 0.5 turn ratio', function ()
      assert.is_true(almost_eq_with_message(-1, cos(0.5)))
    end)

    it('should return 0 for 0.75 turn ratio', function ()
      assert.is_true(almost_eq_with_message(0, cos(0.75)))
    end)

    it('should return 1 for 1 turn ratio', function ()
      assert.is_true(almost_eq_with_message(1, cos(1)))
    end)

  end)

  describe('sin (clockwise)', function ()

    it('should return 0 by default (0 angle)', function ()
      assert.are_equal(0, sin())
    end)

    it('should return 0 for 0 turn ratio', function ()
      assert.are_equal(0, sin(0))
    end)

    it('should return -1 for 0.25 turn ratio', function ()
      assert.is_true(almost_eq_with_message(-1, sin(0.25)))
    end)

    it('should return 0 for 0.5 turn ratio', function ()
      assert.is_true(almost_eq_with_message(0, sin(0.5)))
    end)

    it('should return 1 for 0.75 turn ratio', function ()
      assert.is_true(almost_eq_with_message(1, sin(0.75)))
    end)

    it('should return 0 for 1 turn ratio', function ()
      assert.is_true(almost_eq_with_message(0, sin(1)))
    end)

  end)

  describe('atan2 (clockwise)', function ()

    it('should return 0 for (1, 0)', function ()
      assert.is_true(almost_eq_with_message(0, atan2(1, 0)))
    end)
    it('should return 0.875 for (1, 1)', function ()
      assert.is_true(almost_eq_with_message(0.875, atan2(1, 1)))
    end)
    it('should return 0.75 for (0, 1)', function ()
      assert.is_true(almost_eq_with_message(0.75, atan2(0, 1)))
    end)
    it('should return 0.625 for (-1, 1)', function ()
      assert.is_true(almost_eq_with_message(0.625, atan2(-1, 1)))
    end)
    it('should return.0.5 for (-1, 0)', function ()
      assert.is_true(almost_eq_with_message(0.5, atan2(-1, 0)))
    end)
    it('should return 0.375 for (-1, -1)', function ()
      assert.is_true(almost_eq_with_message(0.375, atan2(-1, -1)))
    end)
    it('should return 0.25 for (0, -1)', function ()
      assert.is_true(almost_eq_with_message(0.25, atan2(0, -1)))
    end)
    it('should return 0.125 for (1, -1)', function ()
      assert.is_true(almost_eq_with_message(0.125, atan2(1, -1)))
    end)
    it('should return 0.875 for (99, 99)', function ()
      assert.is_true(almost_eq_with_message(0.875, atan2(99, 99)))
    end)
    it('should return 0.25 for (0, 0) (special case, equivalent to (0, -1))', function ()
      assert.is_true(almost_eq_with_message(0.25, atan2(0, 0)))
    end)

  end)

  describe('band', function ()

    it('should return binary and result', function ()
      assert.are_equal(0xa0, band(0xa2, 0xa0))
      assert.are_equal(0, band(0xa2, 0x01))
    end)

    it('should return binary or result', function ()
      assert.are_equal(0xa2, bor(0xa2, 0xa0))
      assert.are_equal(0xa3, bor(0xa2, 0x01))
    end)
    it('should return binary xor result', function ()
      assert.are_equal(0x2, bxor(0xa2, 0xa0))
      assert.are_equal(0xa3, bxor(0xa2, 0x01))
      assert.are_equal(0xa2, bxor(0xa3, 0x01))
    end)

    -- be careful, as native Lua doesn't use the same float representation
    -- we simulate what we can in pico8api but negative values will appear differently
    -- so instead of playing with ffff... we use the minus sign for testing

    it('should return binary not result', function ()
      assert.are_equal(-0xb.0001, bnot(0xb))
    end)

    it('should return binary shl result', function ()
      assert.are_equal(0xa200, shl(0xa2, 8))
    end)
    it('should return binary right arithmetic shift result', function ()
      assert.are_equal(0x2, shr(0x200, 8))
      assert.are_equal(0xffa2, shr(0xa200, 8))
    end)
    it('should return binary right logical shift result', function ()
      assert.are_equal(0xa2, lshr(0xa200, 8))
    end)
    it('should return binary rol result', function ()
      assert.are_equal(0x0000.0f00, rotl(0xf000.0000, 12))
    end)
    it('should return binary ror result', function ()
      assert.are_equal(0xf000.0000, rotr(0x0000.0f00, 12))
    end)

  end)

  describe('time', function ()

    setup(function ()
      pico8.frames = 120
    end)

    teardown(function ()
      pico8.frames = 0
    end)

    it('should return the time in sec', function ()
      assert.are_equal(2, time())
    end)

  end)

  describe('buttons', function ()

    setup(function ()
      pico8.keypressed[0] = {
        [0] = true,   -- left
        false,        -- right
        true,         -- up
        false,        -- down
        false,        -- o
        false         -- x
      }
      pico8.keypressed[1] = {
        [0] = false,  -- left
        false,        -- right
        true,         -- up
        true,         -- down
        false,        -- o
        true          -- x
      }
    end)

    teardown(function ()
      clear_table(pico8.keypressed[0])
      clear_table(pico8.keypressed[1])
    end)

    after_each(function ()
      pico8.keypressed.counter = 0
    end)

    describe('btn', function ()


      it('should return the pressed buttons bitfield for both players with no arguments', function ()
        assert.are_equal(1 << 0 | 1 << 2 | 1 << (8+2)| 1 << (8+3) | 1 << (8+5), btn())
      end)

      it('should return whether a player pressed a button (player 0 by default)', function ()
        assert.is_true(btn(2))
        assert.is_false(btn(1))
      end)

      it('should return whether a player pressed a button', function ()
        assert.is_true(btn(2, 0))
        assert.is_true(btn(5, 1))
        assert.is_false(btn(5, 2))
      end)

    end)

    describe('btnp', function ()

      it('should return the just pressed buttons bitfield for both players with no arguments', function ()
        pico8.keypressed.counter = 1
        assert.are_equal(1 << 0 | 1 << 2 | 1 << (8+2)| 1 << (8+3) | 1 << (8+5), btnp())
        pico8.keypressed.counter = 0
        assert.are_equal(0x0, btnp())
      end)

      it('should return whether a player pressed a button (player 0 by default)', function ()
        pico8.keypressed.counter = 1
        assert.is_true(btnp(2))
        assert.is_false(btnp(1))
        pico8.keypressed.counter = 0
        assert.is_false(btnp(2))
      end)

      it('should return whether a player pressed a button', function ()
        pico8.keypressed.counter = 1
        assert.is_true(btnp(2, 0))
        assert.is_true(btnp(5, 1))
        assert.is_false(btnp(5, 2))
        pico8.keypressed.counter = 0
        assert.is_false(btnp(2, 0))
        assert.is_false(btnp(5, 1))
      end)


    end)

  end)

  describe('cartridge data', function ()

    before_each(function ()
      pico8.cartdata[60] = 468
    end)

    after_each(function ()
      pico8.cartdata[60] = nil
    end)

    describe('dget', function ()

      it('should return 0 if value was never set for index', function ()
        assert.are_equal(0, dget(10))
      end)

      it('should return persistent cartridge data at the given index', function ()
        assert.are_equal(468, dget(60))
      end)

      it('should return nil for index out of range', function ()
        assert.is_nil(dget(70))
      end)

    end)

    describe('dset', function ()

      it('should set persistent cartridge data at the given index', function ()
        dset(60, 42)
        assert.are_equal(42, dget(60))
      end)

      it('should do nothing if index is out of range', function ()
        dset(70, 42)
        assert.is_nil(pico8.cartdata[70])
      end)

    end)

  end)

  describe('stat data', function ()

    setup(function ()
      pico8.memory_usage = 124
      pico8.total_cpu = 542
      pico8.system_cpu = 530
      pico8.clipboard = "nice"
      pico8.mousepos.x = 78
      pico8.mousepos.y = 54
      pico8.mousebtnpressed = {false, true, false}
      pico8.mwheel = -2
    end)

    after_each(function ()
      pico8.cartdata[60] = nil
    end)

    describe('stat', function ()

      it('0: memory usage', function ()
        assert.are_equal(124, stat(0))
      end)
      it('1: total cpu', function ()
        assert.are_equal(542, stat(1))
      end)
      it('2: system cpu', function ()
        assert.are_equal(530, stat(2))
      end)
      it('4: clipboard', function ()
        assert.are_equal("nice", stat(4))
      end)
      it('6: 0 (load param not supported)', function ()
        assert.are_equal(0, stat(6))
      end)
      it('7-9: fps (don\'t mind variants)', function ()
        assert.are_equal(60, stat(7))
        assert.are_equal(60, stat(8))
        assert.are_equal(60, stat(9))
      end)
      it('16-23: 0 (audio channels not supported)', function ()
        assert.are_equal(0, stat(20))
      end)
      it('30: 0 (devkit keyboard not supported)', function ()
        assert.are_equal(0, stat(30))
      end)
      it('31: "" (devkit keyboard not supported)', function ()
        assert.are_equal("", stat(31))
      end)
      it('32-33: mouse position', function ()
        assert.are_same({78, 54}, {stat(32), stat(33)})
      end)
      it('31: "" (devkit keyboard not supported)', function ()
        assert.are_equal("", stat(31))
      end)
      it('34: devkit mouse bitfield', function ()
        assert.are_equal(2, stat(34))
      end)
      it('34: devkit mousewheel speed', function ()
        assert.are_equal(-2, stat(36))
      end)
      it('80-85: utc time', function ()
        assert.are_equal(os.date("!*t")["year"], stat(80))
      end)
      it('90-95: local time', function ()
        assert.are_equal(os.date("*t")["year"], stat(90))
      end)
      it('100: nil (load breadcrumb not supported)', function ()
        assert.is_nil(stat(100))
      end)
      it('other: 0', function ()
        assert.are_equal(0, stat(257))
      end)

    end)  -- stat

  end)  -- stat data

  describe('ord', function ()

    it('nil => error (unlike pico8 which returns nothing, for better debug)', function ()
      assert.has_error(function ()
        ord()
      end)
    end)

    it('{} => error (unlike pico8 which returns nothing, for better debug)', function ()
      assert.has_error(function ()
        ord({})
      end)
    end)

    it('"" => error (unlike pico8 which returns nothing, for better debug)', function ()
      assert.has_error(function ()
        ord({})
      end)
    end)

    it('"a" => 97', function ()
      assert.are_equal(97, ord("a"))
    end)

    it('"ab", 1 => 97', function ()
      assert.are_equal(97, ord("ab", 1))
    end)

    it('"ab", 2 => 98', function ()
      assert.are_equal(98, ord("ab", 2))
    end)

    it('"ab", 3 => nil', function ()
      assert.is_nil(ord("ab", 3))
    end)

    it('12, 1 => 49', function ()
      assert.are_equal(49, ord(12, 1))
    end)

    it('12, 2 => 50', function ()
      assert.are_equal(50, ord(12, 2))
    end)

    it('ord("ab", 1, 2) => 97, 98', function ()
      assert.are_same({97, 98}, {ord("ab", 1, 2)})
    end)

    it('ord("abc", 2, 2) => 98, 99', function ()
      assert.are_same({98, 99}, {ord("abc", 2, 2)})
    end)

    it('ord("abc", 2, 3) => 98, 99', function ()
      assert.are_same({98, 99}, {ord("abc", 2, 3)})
    end)

    it('ord(chr(255)) => 255', function ()
      assert.are_equal(255, ord(chr(255)))
    end)

    it('ord(chr(97, 98)) => 97, 98', function ()
      assert.are_same({97, 98}, {ord(chr(97, 98), 1, 2)})
    end)

  end)

  describe('chr', function ()

    it('97 => "a"', function ()
      assert.are_equal("a", chr(97))
    end)

    it('" 97 " => "a"', function ()
      assert.are_equal("a", chr(" 97 "))
    end)

    it('256 + 97 => "a"', function ()
      assert.are_equal("a", chr(256+97))
    end)

    it('97, 98 => "ab"', function ()
      assert.are_equal("ab", chr(97, 98))
    end)

    it('chr(ord("a")) => "a', function ()
      assert.are_equal("a", chr(ord("a")))
    end)

    it('chr(ord("abc")) => "abc', function ()
      assert.are_equal("abc", chr(ord("abc", 1, 3)))
    end)

  end)

  describe('all', function ()

    it('should return an iterator function over a sequence', function ()
      local tab = {4, 5, 9}
      local result = {}
      for value in all(tab) do
        result[#result+1] = value
      end
      assert.are_same(tab, result)
    end)

    it('should skip nil entries, but continue until the end', function ()
      local tab = {4, nil, 9}
      local result = {}
      for value in all(tab) do
        result[#result+1] = value
      end
      assert.are_same({4, 9}, result)
    end)

    it('(busted only) should error for nil', function ()
      assert.has_error(function ()
        all(nil)
      end)

      -- it used to return an empty iterator:
      --[[
      for value in all(nil) do
        -- should never be called
        assert.is_true(false)
      end
      --]]
      -- to match PICO-8 behavior, but I prefer asserting on what I would consider UB
      --  to detect human mistakes early
    end)

    it('should return an empty iterator for an empty sequence', function ()
      for value in all({}) do
        -- should never be called
        assert.is_true(false)
      end
    end)

  end)

  describe('foreach', function ()

    it('should apply a callback function to a sequence', function ()
      local tab = {4, 5, 9}
      local result = {}
      foreach(tab, function (value)
        result[#result+1] = value
      end)
      assert.are_same(tab, result)
    end)

  end)

  describe('count', function ()

    it('should return the number of non-nil elements in a sequence', function ()
      local tab = {1, 2, 3, 4, nil}
      assert.are_equal(4, count(tab))
    end)

  end)

  describe('add', function ()

    -- pico8 0.2.2: fixed add(tab) to do nothing, instead of runtime error
    it('should do nothing when no value is passed', function ()
      local tab = {1, 2, 3, 4}
      add(tab)
      assert.are_same({1, 2, 3, 4}, tab)
    end)

    it('should add an element in a sequence', function ()
      local tab = {1, 2, 3, 4}
      add(tab, 5)
      assert.are_same({1, 2, 3, 4, 5}, tab)
    end)

    it('should insert an element in a sequence with a given index', function ()
      local tab = {1, 2, 3, 4}
      add(tab, 5, 3)
      assert.are_same({1, 2, 5, 3, 4}, tab)
    end)

    -- we are not testing the behavior when the passed table/value is nil, as it does nothing in PICO-8,
    --  but asserts in our implementation to help debugging

  end)

  describe('del', function ()

    it('should remove an element from a sequence', function ()
      local tab = {1, 2, 3, 4}
      del(tab, 2)
      assert.are_same({1, 3, 4}, tab)
    end)

    it('should remove an element from a sequence (by custom equality)', function ()
      local tab = {1, 2, vector(4, 5), 4}
      del(tab, vector(4, 5))
      assert.are_same({1, 2, 4}, tab)
    end)

  end)

  describe('deli', function ()

    it('should remove an element from a sequence by index', function ()
      local tab = {"a", "b", "c"}
      deli(tab, 2)
      assert.are_same({"a", "c"}, tab)
    end)

  end)

  describe('split', function ()

    it('should split with separator comma "," by default, and convert number strings to numbers by default', function ()
      assert.are_same({1, 2, 3}, split("1,2,3"))
    end)

    it('should split with passed separator comma ":", and convert number strings to numbers by default', function ()
      assert.are_same({"one", "two", 3}, split("one:two:3", ":"))
    end)

    it('should split with passed separator comma ":", and preserve numbers as strings when convert_numbers is false', function ()
      assert.are_same({"one", "two", "3"}, split("one:two:3", ":", false))
    end)

    it('should split with separator comma "," by default, and convert number strings to numbers by default, without ever collapsing', function ()
      assert.are_same({1, "", 2, ""}, split("1,,2,"))
    end)

    it('should split every character when separator is empty string "" (like separator = 1), and convert number strings to numbers by default', function ()
      assert.are_same({1, "a", "b", 2, " "}, split("1ab2 ", ""))
    end)

    it('should split every character when separator is empty string "" (like separator = 1), and preserve numbers as strings when convert_numbers is false', function ()
      assert.are_same({"1", "a", "b", "2", " "}, split("1ab2 ", "", false))
    end)

    it('should split every character when separator is number 1, and convert number strings to numbers by default', function ()
      assert.are_same({1, "a", "b", 2, " "}, split("1ab2 ", 1))
    end)

    it('should split every character when separator is number 1, and preserve numbers as strings when convert_numbers is false', function ()
      assert.are_same({"1", "a", "b", "2", " "}, split("1ab2 ", 1, false))
    end)

    it('should split every 2 characters when separator is number 2, and convert number strings to numbers by default', function ()
      assert.are_same({12, 34, 5}, split("12345", 2))
    end)

    it('should split every 2 characters when separator is number 2, and preserve numbers as strings when convert_numbers is false', function ()
      assert.are_same({"12", "34", "5"}, split("12345", 2, false))
    end)

    it('should error when separator has invalid type (unlike PICO-8)', function ()
      assert.has_error(function ()
        split("abc", {"invalid"})
      end)
    end)

  end)

  describe('printh', function ()

    -- caution: this will hide *all* native prints, including debug logs
    -- so we only do this for the utests that really need it
    describe('(stubbing print)', function ()

      local native_print_stub

      setup(function ()
        native_print_stub = stub(_G, "print")  -- native print
      end)

      teardown(function ()
        native_print_stub:revert()
      end)

      after_each(function ()
        native_print_stub:clear()
      end)

      it('should call native print', function ()
        printh("hello")

        assert.spy(native_print_stub).was_called(1)
        assert.spy(native_print_stub).was_called_with("hello")
      end)

    end)

    describe('(with temp file', function ()
      -- in general we should use os.tmpname, but because of the fact
      --   that printh prints to a log folder, we prefer using a custom path
      -- make sure to use a temp dir name that is not an actual folder in the project
      local temp_dirname = "_temp"
      local temp_file_basename = "temp"
      local temp_filepath = temp_dirname.."/"..temp_file_basename..".txt"
      local temp_file = nil

      local function is_dir(dirpath)
        local attr = lfs.attributes(dirpath)
        return attr and attr.mode == "directory"
      end

      -- https://stackoverflow.com/questions/37835565/lua-delete-non-empty-directory
      local function remove_dir_recursive(dirpath)
        for file in lfs.dir(dirpath) do
            local file_path = dirpath..'/'..file
            if file ~= "." and file ~= ".." then
                if lfs.attributes(file_path, 'mode') == 'file' then
                  os.remove(file_path)
                elseif lfs.attributes(file_path, 'mode') == 'directory' then
                  -- just a safety net (if you apply coverage to utest files you'll see it's never called)
                  remove_dir_recursive(file_path)
                end
            end
        end
        lfs.rmdir(dirpath)
      end

      local function remove_if_exists(path)
        local attr = lfs.attributes(path)
        if attr then
          if attr.mode == "directory" then
            remove_dir_recursive(path)
          else
            os.remove(path)
          end
        end
      end

      local function get_lines(file)
        local lines = {}
        for line in file:lines() do
          add(lines, line)
        end
        return lines
      end

      before_each(function ()
        remove_if_exists(temp_dirname)
      end)

      after_each(function ()
        if temp_file then
          -- an error occurred (maybe the assert failed) and the temp file wasn't closed and set to nil
          -- this is never called in working tests
          print("WARNING: emergency close needed, the last write operation likely failed")
          temp_file:close()
        end

        remove_if_exists(temp_dirname)
      end)

      it('should create log directory if it doesn\'t exist', function ()
        printh("hello", temp_file_basename, true, temp_dirname)

        assert.is_true(is_dir(temp_dirname))
      end)

      it('should assert if a non-directory "log" already exists', function ()
        local f,error = io.open(temp_dirname, "w")
        f:close()

        assert.has_error(function ()
          printh("hello", temp_file_basename, true, temp_dirname)
        end, "'_temp' is not a directory but a file")
      end)

      it('should overwrite a file with filepath and true', function ()
        printh("hello", temp_file_basename, true, temp_dirname)

        temp_file = io.open(temp_filepath)
        assert.is_not_nil(temp_file)
        assert.are_same({"hello"}, get_lines(temp_file))
        temp_file = nil
      end)

      it('should append to a file with filepath and false', function ()
        lfs.mkdir(temp_dirname)
        temp_file = io.open(temp_filepath, "w")
        temp_file:write("hello1\n")
        temp_file:close()
        temp_file = nil

        printh("hello2", temp_file_basename, false, temp_dirname)

        temp_file = io.open(temp_filepath)
        assert.is_not_nil(temp_file)
        assert.are_same({"hello1", "hello2"}, get_lines(temp_file))
        temp_file = nil
      end)

      it('should append to a file with filepath and false, adding newline at the end', function ()
        printh("hello1", temp_file_basename, false, temp_dirname)
        printh("hello2", temp_file_basename, false, temp_dirname)
        printh("hello3", temp_file_basename, false, temp_dirname)

        temp_file = io.open(temp_filepath)
        assert.is_not_nil(temp_file)
        assert.are_same({"hello1", "hello2", "hello3"}, get_lines(temp_file))
        temp_file = nil
      end)

    end)

  end)

end)
