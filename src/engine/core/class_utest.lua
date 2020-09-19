require("engine/test/bustedhelper")
require("engine/core/class")  -- already in engine/common, but added for clarity

local dummy_class = new_class()

function dummy_class:init(value)
  self.value = value
end

function dummy_class:_tostring()
  return "dummy:"..tostr(self.value)
end

function dummy_class.__eq(lhs, rhs)
  return lhs.value == rhs.value
end

function dummy_class:get_incremented_value()
  return self.value + 1
end

describe('new_class', function ()

  it('should create a new class with init()', function ()
    local dummy = dummy_class(3)
    assert.are_equal(3, dummy.value)
  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("dummy:12", dummy_class(12):_tostring())
  end)

  it('should support instance concatenation with a string', function ()
    assert.are_equal("dummy:11str", dummy_class(11).."str")
  end)
  it('should support instance concatenation with a boolean', function ()
    assert.are_equal("dummy:11true", dummy_class(11)..true)
  end)
  it('should support instance concatenation with a number', function ()
    assert.are_equal("dummy:1124", dummy_class(11)..24)
  end)
  it('should support instance concatenation with a number on the left', function ()
    assert.are_equal("27dummy:11", "27"..dummy_class(11))
  end)
  it('should support instance concatenation with another instance', function ()
    assert.are_equal("dummy:11dummy:46", dummy_class(11)..dummy_class(46))
  end)
  it('should support instance concatenation with a chain of objects', function ()
    assert.are_equal("dummy:11, and dummy:46", dummy_class(11)..", and "..dummy_class(46))
  end)

  it('should support metamethod: __eq for equality', function ()
    assert.are_equal(dummy_class(-5), dummy_class(-5))
  end)

  it('should support metamethod: __eq for inequality', function ()
    assert.are_not_equal(dummy_class(-5), dummy_class(-3))
  end)

  it('should support custom method: get_incremented_value', function ()
    assert.are_equal(-4, dummy_class(-5):get_incremented_value())
  end)

end)

describe('derived_class', function ()

  it('should error when passing nil', function ()
    assert.has_error(function ()
      derived_class(nil)
    end)
  end)

  describe('dummy derived class', function ()

    local dummy_derived_class = derived_class(dummy_class)

    function dummy_derived_class:init(value, value2)
      -- always call .init on base class, never :init which would set static members
      dummy_class.init(self, value)
      self.value2 = value2
    end

    function dummy_derived_class:_tostring()
      return "dummy_derived:"..tostr(self.value)..","..tostr(self.value2)
    end

    function dummy_derived_class.__eq(lhs, rhs)
      return lhs.value == rhs.value and lhs.value2 == rhs.value2
    end

    it('should create a new dummy_derived_class with a value attribute', function ()
      local dummy_derived = dummy_derived_class(3, 7)
      assert.are_same({3, 7}, {dummy_derived.value, dummy_derived.value2})
    end)

    it('should support custom method: _tostring', function ()
      assert.are_equal("dummy_derived:12,45", dummy_derived_class(12, 45):_tostring())
    end)

    it('should support instance concatenation with a string', function ()
      assert.are_equal("dummy_derived:11,45str", dummy_derived_class(11, 45).."str")
    end)
    it('should support instance concatenation with a boolean', function ()
      assert.are_equal("dummy_derived:11,45true", dummy_derived_class(11, 45)..true)
    end)
    it('should support instance concatenation with a number', function ()
      assert.are_equal("dummy_derived:11,4524", dummy_derived_class(11, 45)..24)
    end)
    it('should support instance concatenation with a number on the left', function ()
      assert.are_equal("27dummy_derived:11,45", "27"..dummy_derived_class(11, 45))
    end)
    it('should support instance concatenation with another instance of dummy_derived', function ()
      assert.are_equal("dummy_derived:11,45dummy_derived:46,23", dummy_derived_class(11, 45)..dummy_derived_class(46, 23))
    end)
    it('should support instance concatenation with an instance of dummy', function ()
      assert.are_equal("dummy_derived:11,45dummy:46", dummy_derived_class(11, 45)..dummy_class(46))
    end)
    it('should support instance concatenation within a chain of objects', function ()
      assert.are_equal("dummy_derived:11,45, and dummy:46", dummy_derived_class(11, 45)..", and "..dummy_class(46))
    end)

    it('should support metamethod: __eq for equality', function ()
      assert.are_equal(dummy_derived_class(-5, 45), dummy_derived_class(-5, 45))
    end)

    it('should support metamethod: __eq for inequality', function ()
      assert.are_not_equal(dummy_derived_class(-5, 45), dummy_derived_class(-5, 43))
    end)

    it('should allow access to base class custom method: get_incremented_value', function ()
      assert.are_equal(-4, dummy_derived_class(-5, 45):get_incremented_value())
    end)

  end)

end)

describe('new_struct', function ()

  local dummy_struct = new_struct()

  function dummy_struct:init(value1, value2)
    self.value1 = value1
    self.value2 = value2
  end

  function dummy_struct:_tostring()
    return "dummy: "..joinstr(", ", self.value1, self.value2)
  end

  function dummy_struct:get_sum()
    return self.value1 + self.value2
  end

  local complex_struct = new_struct()

  function complex_struct:init(value1, value2)
    self.sum = value1 + value2
    self.sub_struct = dummy_struct(value1, value2)
  end

  function complex_struct:_tostring()
    return "complex_struct: "..joinstr(", ", self.sum, self.sub_struct)
  end

  local invalid_struct = new_struct()

  function invalid_struct:init(value)
    self.table = dummy_class(value)  -- struct should never contain non-struct tables
  end

  local struct_with_spied_function = new_struct()

  function struct_with_spied_function:init(callback)
    self.callback = spy.new(callback)  -- to test allowing copy of those
  end

  it('should create a new struct with init()', function ()
    local dummy = dummy_struct(3, 7)
    assert.are_same({3, 7}, {dummy.value1, dummy.value2})
  end)

  it('should create a new struct with access to methods via __index', function ()
    local dummy = dummy_struct(3, 7)
    assert.are_equal(10, dummy:get_sum())
  end)

  describe('copy', function ()

    it('should error if the struct contains non-struct members at some depth level', function ()
      assert.has_error(function ()
        invalid_struct(99):copy()
      end, "value dummy:99 is a table member of a struct but it doesn't have expected copy method, so it's not a struct itself")
    end)

    -- bugfix history: +
    it('should return a copy of the struct, with the same content but not the same reference', function ()
      local dummy = dummy_struct(3, 7)
      local copied_dummy = dummy:copy()

      assert.are_same(dummy, copied_dummy)  -- are_equal also works, provided __eq is working
      assert.is_false(rawequal(dummy, copied_dummy))
    end)

    it('should return a copy of the struct even if it contains a spied function, copying the spy by reference', function ()
      local s_with_spied_function = struct_with_spied_function(function () end)
      local copied_s_with_spied_function = s_with_spied_function:copy()

      -- rather than testing are_same, we test for equality by reference of the callback members
      --   which is stronger (just to show we are using the same spies for convenience)
      assert.are_equal(s_with_spied_function.callback, copied_s_with_spied_function.callback)
      assert.is_false(rawequal(s_with_spied_function, copied_s_with_spied_function))
    end)

    describe('with struct containing struct', function ()

      it('should return a copy of the struct and its struct members, with the same contents but not the same references', function ()
        local complex = complex_struct(3, 7)
        local copied_complex = complex:copy()

        assert.are_same(complex, copied_complex)
        assert.is_false(rawequal(complex, copied_complex))
        assert.are_same(complex.sub_struct, copied_complex.sub_struct)
        assert.is_false(rawequal(complex.sub_struct, copied_complex.sub_struct))
      end)

    end)

  end)

  describe('copy_assign', function ()

    it('should error if self and from have different types', function ()
      local simple_from = dummy_struct(3, 7)
      local complex_to = complex_struct(4, 5)

      assert.has_error(function ()
        complex_to:copy_assign(simple_from)
      end, "copy_assign: expected 'self' (complex_struct: 9, dummy: 4, 5) and 'from' (dummy: 3, 7) to have the same struct type")
    end)

    it('should error if the struct contains non-struct members at some depth level', function ()
      assert.has_error(function ()
        invalid_struct(9):copy_assign(invalid_struct(99))
      end, "value dummy:99 is a table member of a struct but it doesn't have expected copy_assign method, so it's not a struct itself")
    end)

    it('should assign all the values of `from` to `to`', function ()
      local from = dummy_struct(3, 7)
      local to = dummy_struct(99, -99)

      to:copy_assign(from)

      assert.are_same(from, to)  -- are_equal also works, provided __eq is working
    end)

    describe('with struct containing struct', function ()

      it('should return a copy of the struct and its struct members, with the same contents but not the same references', function ()
        local from = complex_struct(3, 7)
        local to = complex_struct(99, -99)
        -- let's check that a brand new embedded struct is created (the test below with nil also shows that)
        -- see are_not_equal below
        local old_sub_struct_ref = to.sub_struct

        to:copy_assign(from)

        assert.are_same(from, to)
        -- struct equality has been removed by default,
        --  so we could also check are_not_equal now
        assert.is_false(rawequal(from, to))
        assert.are_same(from.sub_struct, to.sub_struct)
        assert.is_false(rawequal(old_sub_struct_ref, to.sub_struct))
        assert.is_false(rawequal(from.sub_struct, to.sub_struct))
      end)

      it('should also work when the embedded value supposed to be a struct is initally nil, by creating a brand new copy of the other value', function ()
        local from = complex_struct(3, 7)
        local to = complex_struct(99, -99)
        to.sub_struct = nil

        to:copy_assign(from)

        assert.are_same(from, to)
        assert.is_false(rawequal(from, to))
        assert.are_same(from.sub_struct, to.sub_struct)
        assert.is_false(rawequal(from.sub_struct, to.sub_struct))
      end)

    end)

  end)

  describe('dummy_derived struct', function ()

    local dummy_derived_struct = derived_struct(dummy_struct)

    function dummy_derived_struct:init(value1, value2, value3)
      -- always call .init on base struct, never :init which would set static members
      dummy_struct.init(self, value1, value2)
      self.value3 = value3
    end

    function dummy_derived_struct:_tostring()
      return "dummy_derived_struct: "..joinstr(", ", self.value1, self.value2, self.value3)
    end

    function dummy_derived_struct:get_sum()
      return dummy_struct.get_sum(self) + self.value3
    end

    it('should create a new struct with init()', function ()
      local dummy_derived = dummy_derived_struct(3, 7, 9)
      assert.are_same({3, 7, 9}, {dummy_derived.value1, dummy_derived.value2, dummy_derived.value3})
    end)

    it('should create a new struct with access to methods via __index (override calling base)', function ()
      local dummy_derived = dummy_derived_struct(3, 7, 9)
      assert.are_equal(19, dummy_derived:get_sum())
    end)

    it('should support instance concatenation', function ()
      local dummy_derived = dummy_derived_struct(3, 7, 9)
      assert.are_equal("val: dummy_derived_struct: 3, 7, 9", "val: "..dummy_derived)
    end)

  end)

end)

describe('singleton', function ()

  local my_singleton = singleton(function (self)
    self.type = "custom"
  end)

  function my_singleton:_tostring()
    return "[my_singleton "..self.type.."]"
  end

  it('should define a singleton with unique members', function ()
    assert.are_equal("custom", my_singleton.type)
  end)

  describe('changing member', function ()

    setup(function ()
      my_singleton.type = "changed"
    end)

    teardown(function ()
      my_singleton.type = "custom"
    end)

    it('init should reinit the state vars', function ()
      my_singleton:init()
      assert.are_equal("custom", my_singleton.type)
    end)

  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("[my_singleton custom]", my_singleton:_tostring())
  end)

  it('should support string concatenation with _tostring', function ()
    assert.are_equal("this is [my_singleton custom]", "this is "..my_singleton)
  end)

end)

describe('derived_singleton', function ()

  local my_singleton = singleton(function (self)
    self.types = { "custom" }  -- the table allows us to check if __index in derived_singleton reaches it by ref to change it
  end)

  function my_singleton:get_first_type()
    return self.types[1]
  end

  function my_singleton:_tostring()
    return "[my_singleton "..self.types[1].."]"
  end

  local my_derived_singleton = derived_singleton(my_singleton, function (self)
    self.subtype = "special"
  end)

  function my_derived_singleton:_tostring()
    return "[my_derived_singleton "..my_singleton._tostring(self)..", "..self.subtype.."]"
  end

  local my_derived_singleton_noinit = derived_singleton(my_derived_singleton)

  function my_derived_singleton_noinit:new_method()
    return 5
  end

  it('should define a derived_singleton with base members', function ()
    assert.are_equal("custom", my_derived_singleton.types[1])
  end)

  it('should define a derived_singleton with derived members using derivedinit', function ()
    assert.are_equal("special", my_derived_singleton.subtype)
  end)

  it('should define a derived_singleton with derived members with same init if none is provided', function ()
    assert.are_equal("special", my_derived_singleton_noinit.subtype)
  end)

  it('should define a derived_singleton with new methods', function ()
    assert.are_equal(5, my_derived_singleton_noinit.new_method())
  end)

  describe('changing base member copy', function ()

    before_each(function ()
      my_derived_singleton.types[1] = "changed"
    end)

    after_each(function ()
      my_derived_singleton.types[1] = "custom"
    end)

    it('should create a copy of base members on the derived singleton so they are never changed on the base singleton', function ()
      assert.are_equal("custom", my_singleton.types[1])
    end)

    describe('changing base member copy', function ()

      before_each(function ()
        my_derived_singleton.subtype = "subchanged"
      end)

      after_each(function ()
        my_derived_singleton.subtype = "special"
      end)

      it('init should reinit the state vars', function ()
        assert.are_equal("changed", my_derived_singleton.types[1])
        assert.are_equal("subchanged", my_derived_singleton.subtype)
        my_derived_singleton:init()
        assert.are_equal("custom", my_derived_singleton.types[1])
        assert.are_equal("special", my_derived_singleton.subtype)
      end)

    end)

  end)

  it('should access base method: get_first_type', function ()
    assert.are_equal("custom", my_derived_singleton:get_first_type())
  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("[my_derived_singleton [my_singleton custom], special]", my_derived_singleton:_tostring())
  end)

  it('should support string concatenation with _tostring', function ()
    assert.are_equal("this is [my_derived_singleton [my_singleton custom], special]", "this is "..my_derived_singleton)
  end)

end)
