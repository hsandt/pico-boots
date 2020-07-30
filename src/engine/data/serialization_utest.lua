require("engine/test/bustedhelper")
local serialization = require("engine/data/serialization")

describe('serialization', function ()

  describe('read_from_string', function ()

    it('should parse a sequence of numbers and strings', function ()
      assert.are_same(
        {-42, "top", {"one", {"one a", "one b"}}, {"two", {"two a", "two b"}}}, serialization.read_from_string(
       '{-42, "top", {"one", {"one a", "one b"}}, {"two", {"two a", "two b"}}}'))
    end)

    it('#mute should parse a map of numbers and strings', function ()
      assert.are_same(
        {key = {[5] = "ok", ["hey"] = -12}, key2 = "nice"}, serialization.read_from_string(
       '{key = {[5] = "ok", ["hey"] = -12}, key2 = "nice"}'))
    end)

  end)

  describe('unpack', function ()

    -- no initial brace, no numbers are assumed strings
    it('should parse a simple table', function ()
      assert.are_same(
        {"a"}, unpack(
        'a'))
    end)

    it('should parse a simple table', function ()
      assert.are_same(
        {a = "b"}, unpack(
        'a=b'))
    end)

    it('should parse a sequence of numbers and strings', function ()
      assert.are_same(
        {x=1,y=3,type=0,ents={{x=56,y=76,props={sdir=0.5,scone=0.125,swing=0.12,rate=0.00869,t=0,rad=64},n=218,tfra=8,type=0,update="pvis"},{x=104,y=42,props={sdir=0.25,scone=0.125,swing=0.25,rate=0.00869,t=0.5,rad=48},n=218,tfra=8,type=0,update="pvis"}}}, unpack(
        'x=1,y=3,type=0,ents={{x=56,y=76,props={sdir=0.5,scone=0.125,swing=0.12,rate=0.00869,t=0,rad=64},n=218,tfra=8,type=0,update=pvis},{x=104,y=42,props={sdir=0.25,scone=0.125,swing=0.25,rate=0.00869,t=0.5,rad=48},n=218,tfra=8,type=0,update=pvis}}'))
    end)

  end)

  describe('unpack_custom', function ()

    it('should parse a simple table', function ()
      assert.are_same(
        {"a"}, unpack_custom(
        'a'))
    end)

    it('should parse a simple table', function ()
      assert.are_same(
        {a = "b"}, unpack_custom(
        'a=b'))
    end)

    it('#solo should parse a simple table with space', function ()
      assert.are_same(
        {a = "b"}, unpack_custom(
        ' a = b'))
    end)

    it('should parse a sequence of numbers and strings', function ()
      assert.are_same(
        {-42, "top", {"one", {"one a", "one b"}}, {"two", {"two a", "two b"}}}, unpack_custom(
       '-42, "top", {"one", {"one a", "one b"}}, {"two", {"two a", "two b"}}'))
    end)

    it('should parse a map of numbers and strings', function ()
      assert.are_same(
        {key = {[5] = "ok", ["hey"] = -12}, key2 = "nice"}, unpack_custom(
       'key = {[5] = "ok", ["hey"] = -12}, key2 = "nice"'))
    end)

  end)

end)
