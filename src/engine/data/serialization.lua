local serialization = {}

-- Egor Skriptunoff
-- https://stackoverflow.com/questions/51701629/deserialization-of-simple-lua-table-stored-as-string
local function is_digit(c)
   return c >= '0' and c <= '9'
end

-- FLAW: only supports sequences
function serialization.read_from_string(input)
   if type(input) == 'string' then
      local data = input
      local pos = 0
      function input(undo)
         if undo then
            pos = pos - 1
         else
            pos = pos + 1
            return string.sub(data, pos, pos)
         end
      end
   end
   local c
   repeat
      c = input()
   until c ~= ' ' and c ~= ','
   if c == '"' then
      local s = ''
      repeat
         c = input()
         if c == '"' then
            return s
         end
         s = s..c
      until c == ''
   elseif c == '-' or is_digit(c) then
      local s = c
      repeat
         c = input()
         local d = is_digit(c)
         if d then
            s = s..c
         end
      until not d
      input(true)
      return tonumber(s)
   elseif c == '{' then
      local arr = {}
      local elem
      repeat
         elem = serialization.read_from_string(input)
         table.insert(arr, elem)
      until not elem
      return arr
   end
end

-- attempt to support keys
function serialization.read_table_from_string(input)
   if type(input) == 'string' then
      local data = input
      local pos = 0
      function input(undo)
         if undo then
            pos = pos - 1
         else
            pos = pos + 1
            return string.sub(data, pos, pos)
         end
      end
   end

   local key
   -- sequence (no key) auto-increment
   local auto = 1

   local c
   repeat
      c = input()
   until c ~= ' ' and c ~= ','
   if c == '=' then
   elseif c == '"' then
      local s = ''
      repeat
         c = input()
         if c == '"' then
            return s
         end
         s = s..c
      until c == ''
   elseif c == '-' or is_digit(c) then
      local s = c
      repeat
         c = input()
         local d = is_digit(c)
         if d then
            s = s..c
         end
      until not d
      input(true)
      return tonumber(s)
   elseif c == '{' then
      local arr = {}
      local elem
      repeat
         elem = serialization.read_from_string(input)
         -- table.insert(arr, elem)
      until not elem
      return arr
   end
end


local data_string = '{-42, "top", {"one", {"one a", "one b"}}, {"two", {"two a", "two b"}}}'
local obj = serialization.read_from_string(data_string)
-- obj == {-42, "top", {"one", {"one a", "one b"}}, {"two", {"two a", "two b"}}}
printh("obj: "..dump(obj))

--
-- https://www.lexaloffle.com/bbs/?tid=2423
function unpack(s)
 local a={}
 local key,val,c,auto,ob
 local i=1
 local l=0
 s=s..","  auto=1
 while i<=#s do
  c=sub(s,i,i)
  if c=="{" then
   l=i
   ob=1
   while ob>0 do
    -- i+=1
    i=i+1
    c=sub(s,i,i)
    -- if c=="}" then ob-=1
    -- elseif c=="{" then ob+=1 end
    if c=="}" then ob=ob-1
    elseif c=="{" then ob=ob+1 end
   end
   val=unpack(sub(s,l+1,i-1))
   if not key then
    key=auto
    -- auto+=1
    auto=auto+1
   end
   a[key]=val
   key=false
   -- i+=1 --skip comma
   i=i+1 --skip comma
   l=i
  elseif c=="=" then
   key=sub(s,l+1,i-1)
   l=i
  elseif c=="," and l~=i-1 then
   val=sub(s,l+1,i-1)
   local valc=sub(val,#val,#val)
   if valc>="0" and valc<="9" then
    val=val*1
    -- cover for a bug in string conversion
    printh("val: "..dump(val))
    -- fails if val is not integer...
    -- val=shl(shr(val,1),1)
   elseif val=="true" then
    val=true
   elseif val=="false" then
    val=false
   end
   -- trying to fix "pvis" not stringified, just nil
   printh("val: "..dump(val))
   l=i
   if not key then
    key=auto
    -- auto+=1
    auto=auto+1
   end
   a[key]=val
   key=false
  end
  -- i+=1
  i=i+1
 end
 return a
end

-- trying to support spaces, etc.
function unpack_custom(s)
  local a={}
  local key,val,c,auto,ob
  local i=1
  -- start of currently parsed symbol
  local l=0
  s=s..","

  -- sequence (no key) auto-increment
  auto = 1

  while i <= #s do
    c = sub(s, i, i)
    if c=="{" then
      l = i
      ob = 1
      -- seek end of {}
      while ob > 0 do
        i = i+1
        c = sub(s, i, i)
        if c == "}" then ob = ob-1
          elseif c == "{" then ob = ob+1 end
        end
        -- recursion
        val = unpack(sub(s, l+1, i-1))
        if not key then
          key=auto
        auto = auto+1
      end

      a[key]=val
      key=false

      i=i+1 --skip comma
      l=i
    elseif c=="=" then
      key=sub(s,l+1,i-1)
      l=i
      printh("key: "..dump(key))
      printh("l: "..dump(l))
    elseif c=="," and l~=i-1 then
      val = sub(s,l+1,i-1)
      local valc = sub(val, #val, #val)
      if valc>="0" and valc<="9" then
        val=val*1
        -- cover for a bug in string conversion
        printh("val: "..dump(val))
        -- fails if val is not integer...
        -- val=shl(shr(val,1),1)
      elseif val=="true" then
        val=true
      elseif val=="false" then
        val=false
      end
      -- trying to fix "pvis" not stringified, just nil
      printh("val: "..dump(val))
      l=i

      if not key then
        key=auto
        auto=auto+1
      end

      a[key]=val
      key=false
    elseif c == " " then
      -- l = l + 1
      printh("l: "..dump(l))
    end

    i=i+1
  end

  return a
end

return serialization
