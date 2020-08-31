-- generic new metamethod (requires _init method)
local function new(cls, ...)
  local self = setmetatable({}, cls)  -- cls as instance metatable
  self:_init(...)
  return self
end

-- generic concat metamethod (requires _tostring method on tables)
local function concat(lhs, rhs)
--[[#pico8
--#ifn log
  -- caution: concat cannot be used as log symbol is not defined for this config
  return tostr(lhs)..tostr(rhs)
--#endif
--#pico8]]
--#if log
  return stringify(lhs)..stringify(rhs)
--#endif
end

-- return a copy of a struct instance 'self'
-- this is a simplified version of deepcopy implementations and only support
--   structs referencing primitive types or structs (at least copy-able tables)
--   with no reference cycle
-- Generally speaking, we recommend to always use copy when initializing a struct value
--   from another, just like you would copy construct in C++ / define struct variable in C#.
-- This will avoid unwanted changes in the source struct when modifying the new one.
-- Ex: new_value = source:copy()
--     new_value.x = 5  -- safe
-- Similarly, functions that return another struct with modified content from an initial struct,
-- but that sometimes don't do anything (e.g. clamp) should return `source:copy()`
-- instead of `source` (or `self:copy()` instead of `self` for methods) when nothing is done.
-- You can exceptionally keep a reference to the source struct table, as you would
--   with a const & in C++, but only if you are sure you will not modify it.
local function copy(self)
  -- we can't access the struct type from here so we get it back via getmetatable
  local copied = setmetatable({}, getmetatable(self))

  for key, value in pairs(self) do
    local force_shallow_copy = false
--#if busted
    --[[
    busted uses luaassert spies, which hijack functions by replacing them
      with tables, so unit tests relying on copying a struct containing a spied function
      will assert here; so, exceptionally allow shallow copy of those (just use reference to spy)
    A spy is like this:
      {returnvals = {}, callback = [function], clear = [function], calls = {}, called = [function], called_with = [function], revert = [function], returned_with = [function]}
      but we just check a few elements not likely to exist on our own classes (and that copy doesn't exist to start with)
    --]]
    if type(value) == 'table' and value.copy == nil and type(value.callback) == 'function' and type(value.called_with) == 'function' then
      force_shallow_copy = true
    end
--#endif
    if type(value) == 'table' and not force_shallow_copy then
--#if assert
      assert(type(value.copy) == 'function', "value "..nice_dump(value)..
        " is a table member of a struct but it doesn't have expected copy method, so it's not a struct itself")
--#endif
      -- deep copy the struct member itself. never use circular references
      -- between structs or you'll get an infinite recursion
      copied[key] = value:copy()
    else
      copied[key] = value
    end
  end

  return copied
end

-- copy assign struct members of 'from' to struct members of 'self'
-- from and to must be struct instances of the same type
-- copy_assign is useful when manipulating a struct instance reference whose content
--  must be changed in-place, because the function caller will continue using the same reference
-- Generally speaking, we recommend using copy_assign every time you assign you must copy a struct
--   into an existing target struct, just like you would copy assign in C++ / assign struct in C#.
-- Ex: target:copy_assign(source)
--     target.x = 5  -- safe
-- You can exceptionally keep a reference to the source struct table, as you would
--   with a const & in C++, but only if you are sure you will not modify it.
local function copy_assign(self, from)
  assert(getmetatable(self) == getmetatable(from), "copy_assign: expected 'self' ("..self..") and 'from' ("..from..") to have the same struct type")

  for key, value in pairs(from) do
    if type(value) == 'table' then
--#if assert
      assert(type(value.copy_assign) == 'function', "value "..stringify(value)..
        " is a table member of a struct but it doesn't have expected copy_assign method, so it's not a struct itself")
--#endif
      -- recursively copy-assign the struct members. never use circular references
      -- between structs or you'll get an infinite recursion
      self[key]:copy_assign(value)
    else
      self[key] = value
    end
  end
end

--[[
Create and return a new class

Every class should implement
  - `:_init()`,
  - if useful for logging, `:_tostring()`
  - if relevant, `.__eq()`

Note that most .__eq() definitions are only duck-typing lhs and rhs,
  so we can compare two instances of different classes (maybe related by inheritance)
  with the same members. slicing will occur when comparing a base instance
  and a derived instance with more members. add a class type member to simulate RTTI
  and make sure only objects of the same class are considered equal (but we often don't need this)
We recommend using a struct for simple structures, as they implement __eq automatically.
--]]
function new_class()
  local class = {}
  class.__index = class  -- 1st class as instance metatable
  class.__concat = concat

  setmetatable(class, {
    __call = new
  })

  return class
end

--[[
Create and return a new class derived from a base class

base_class should have itself been created with new_class or derived_class.

It behaves like new_class, but adds __index = base_class in the metatable
You must override `:_init` and call `base_class._init(self, ...)` inside
  if you want to preserve base implementation
--]]
function derived_class(base_class)
  -- developer may inadvertently pass nil object when forgetting a require
  assert(base_class, "derived_class: no base class passed")

  local class = {}
  class.__index = class  -- 1st class as instance metatable
  class.__concat = concat

  setmetatable(class, {
    __index = base_class,
    __call = new
  })

  return class
end

-- create a new struct, which is like a class with member-wise equality
function new_struct()
  local struct = {}
  struct.__index = struct  -- 1st struct as instance metatable
  struct.__concat = concat
  struct.copy = copy
  struct.copy_assign = copy_assign

  setmetatable(struct, {
    __call = new
  })

  return struct
end

-- create and return a derived struct from a base struct, redefining metamethods for this level
function derived_struct(base_struct)
  local derived = {}
  derived.__index = derived
  derived.__concat = concat

  setmetatable(derived, {
    __index = base_struct,
    __call = new
  })

  return derived
end

-- create a new singleton from an init method, which can also be used as reset method in unit tests
-- the singleton is at the same time a class and its own instance
function singleton(init)
  local s = {}
  setmetatable(s, {
    __concat = concat
  })
  s.init = init
  s:init()
  return s
end

-- create a singleton from a base singleton and an optional derived_init method, so it can extend
-- the functionality of a singleton while providing new static fields on the spot
-- derived_init should *not* call base_singleton.init, as it is already done in the construct-time init
function derived_singleton(base_singleton, derived_init)
  local ds = {}
  -- do not set __index to base_singleton in metatable, so ds never touches the members
  -- of the base singleton (if the base singleton is concrete or has other derived singletons,
  -- this would cause them to all share and modify the same members)
  setmetatable(ds, {
    -- __index allows the derived_singleton to access base_singleton methods
    -- never define an attribute on a singleton outside init (e.g. using s.attr = value)
    -- as the "super" init in ds:init would not be able to shadow that attr with a personal attr
    -- for the derived_singleton, which would access the base_singleton's attr via __index,
    -- effectively sharing the attr with all the other singletons in that hierarchy!
    __index = base_singleton,
    __concat = concat
  })
  function ds:init()
    base_singleton.init(self)
    if derived_init then
      derived_init(self)
    end
  end
  ds:init()
  return ds
end
