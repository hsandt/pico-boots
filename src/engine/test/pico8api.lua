--#if busted
-- just strip the whole file for build; of course it's never required by actual
--  PICO-8 cartridge scripts, but replace_strings doesn't know about that
--  and will try to process this file, finding false negative errors like "api.lua"
--  using namespace "api." with unknown function "lua" if we write this outside
--  a full line comment (whcih preprocess does strip already)

-- pico-8 api placeholders for tests run under vanilla lua
-- pico8:method calls in non-test scripts should be surrounded by
-- "--#if busted" but don't need a require("engine/test/pico8api") (since they will
-- always be required by a utest script already requiring bustedhelper)

-- credits
--
-- functions taken from gamax92's fork of picolove
-- https://github.com/gamax92/picolove/blob/master/api.lua
-- pico8 table taken from:
-- https://github.com/gamax92/picolove/blob/master/main.lua
-- original repository by jez kabanov
-- https://github.com/picolove/picolove
-- both under zlib license
-- see readme.md for more information

-- lua 5.3 supports binary ops but still useful for advanced ops
local bit = require("bit32")

pico8={
  fps=60,
  memory_usage=0,
  total_cpu=0,
  system_cpu=0,
  frames=0,
  spriteflags={},
  current_music=nil,
  cartdata={},
  clipboard="",
  keypressed={
    [0]={},
    [1]={},
    counter=0
  },
  mousepos={  -- simulate mouse position
    x=0,
    y=0
  },
  mousebtnpressed={  -- simulate mouse buttons
    false,
    false,
    false
  },
  mwheel=0,
  camera_x=0,
  camera_y=0,
  clip={0, 0, 128, 128},
  pal_transparent={},
  map={},
  poked_addresses={}  -- not a complete simulation of memory, just of poked addresses set to value
}

for i=0, 15 do
  -- set all but black to opaque, black to transparent (similar to palt() implementation)
  pico8.pal_transparent[i] = i == 0 and true or false
end

-- busted-only helper to clear the map, as memset(0x2000, 0, 0x1000) wouldn't work
function pico8:clear_map()
  for y = 0, 63 do
    self.map[y] = {}
    for x = 0, 127 do
      self.map[y][x] = 0
    end
  end
end

-- busted-only helper to clear the spriteflags, as memset(0x3000, 0, 0x100) wouldn't work
--  and we don't really do that in pico8 anyway
function pico8:clear_spriteflags()
  for n = 0, 255 do
    self.spriteflags[n] = 0
  end
end

pico8:clear_spriteflags()
pico8:clear_map()

function camera(x, y)
  pico8.camera_x=flr(x)
  pico8.camera_y=flr(y)
end

function clip(x, y, w, h)
  -- almost like pico8: if an arg is not missing but explicitly
  -- passed as nil, it will become 0 (but that's impossible to check in lua)
  if x and y and w and h then
    pico8.clip={flr(x), flr(y), flr(w), flr(h)}
  else
    local previous_state = pico8.clip
    pico8.clip={0, 0, 128, 128}
    return unpack(previous_state)
  end
end

function cls(c)
  pico8.clip={0, 0, 128, 128}
end

function pset(x, y, c)
  if c then
    color(c)
  end
end

function pget(x, y)
  return 0
end

function color(c)
  c=flr(c or 0)%16
  pico8.color=c
end

function cursor(x, y)
end

-- convert string to number, preserve number
-- return nil if it fails to parse
function tonum(val)
  return tonumber(val) -- not a direct assignment to prevent usage of the radix argument
end

-- extra function not present in PICO-8 that floors number to fixed point precision,
--  useful for precise numerical tests
function to_fixed_point(val)
  -- binary operations don't work well with negative numbers (unlike tostr that is
  --  just reading values), so work on absolute value and re-add sign at the end
  local sign = sgn(val)
  local full_val = flr(abs(val)*0x10000)
  return sign * lshr(full_val, 16)

  -- alternative 1 (it's literally lshr inlined)
  -- return sign * (full_val * 0x10000 >> 16) / 0x10000

  -- alternative 2 (reuse dual part technique of tostr)
  -- local part1 = (full_val & 0xffff0000) >> 16  -- fixed from original api.lua
  -- local part2 = full_val & 0xffff
  -- return sign * (part1 + part2 / 0x10000)
end

-- http://pico-8.wikia.com/wiki/tostr
-- slight difference with pico8 0.2: when passing the result of a function
-- that returns nothing, we return "[nil]" instead of nil
function tostr(...)
  -- {...} will create a sequence of length 1 containing nil, so the only way
  --  to really distinguish no argument from passed nil is to use select
  -- note that it only works in native Lua, but that's what bridge is for
  local n = select("#", ...)
  local val = select("1", ...)  -- or args[1]
  local hex = select("2", ...)  -- or args[2]

  -- since pico8 0.2.2
  if n == 0 then
    return ""
  end

  local kind=type(val)
  if kind == "string" then
    return val
  elseif kind == "number" then
    if hex then
      -- in floating-point precision lua, val may have more that 4 hex figures
      --  after the hexadecimal point
      val=flr(val*0x10000)
      local part1=(val & 0xffff0000) >> 16  -- fixed from original api.lua
      local part2=val & 0xffff
      return string.format("0x%04x.%04x", part1, part2)
    else
      return tostring(val)
    end
  elseif kind == "boolean" then
    -- this is even more precise that pico8 tostr, that will skip the last decimals (e.g. 1e-4 in 1+1e-4),
    --  even if fixed point precision didn't lose them. but it's fine since it's mostly useful to debug failing tests
    return tostring(val)
  else
    -- function, table, thread
    -- functions and tables will be printed like tostring with address if hex is true
    if (kind == "function" or kind == "table") and hex then
      return tostring(val)
    else
      -- this includes [nil], which is different from passing nothing (see n at the top)
      return "[" .. kind .. "]"
    end
  end
end

function spr(n, x, y, w, h, flip_x, flip_y)
end

function sspr(sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y)
end

function rect(x0, y0, x1, y1, col)
  if col then
    color(col)
  end
end

function rectfill(x0, y0, x1, y1, col)
  if col then
    color(col)
  end
end

function circ(ox, oy, r, col)
  if col then
    color(col)
  end
end

function circfill(cx, cy, r, col)
  if col then
    color(col)
  end
end

-- pico8 0.2.1
-- TODO: add oval and ovalfill

function line(x0, y0, x1, y1, col)
  if col then
    color(col)
  end
end

function tline(x0, y0, x1, y1, mx, my, mdx, mdy, layers)
  -- no implementation for visual function
end

function pal(c0, c1, p)
  -- the 2nd nil means undefined here, but we can't check in lua
  if c0 == nil and c1 == nil then
    palt()
  end
end

function palt(c, tc)
  if c == nil and tc == nil then
    for i=0, 15 do
      -- reset all but black to opaque, black to transparent
      pico8.pal_transparent[i] = i == 0 and true or false
    end
  elseif tc == nil then
    -- only c has been passed, it must be a bitmask (low-endian, so lower color index first)
    for i = 0, 15 do
      -- we don't use color_to_bitmask just because pico8api is required early, possibly before color.lua
      pico8.pal_transparent[i] = bit.btest(c, 1 << 15 - i)
    end
  else
    c = flr(c)%16
    pico8.pal_transparent[c] = tc
  end
end

function fillp(p)
end

function map(cel_x, cel_y, sx, sy, cel_w, cel_h, bitmask)
end

function mget(x, y)
  x=flr(x or 0)
  y=flr(y or 0)
  if x>=0 and x<128 and y>=0 and y<64 then
    return pico8.map[y][x]  -- will be nil if not set in test before
  end
  return 0
end

function mset(x, y, v)
  x=flr(x or 0)
  y=flr(y or 0)
  v=flr(v or 0)%256
  if x>=0 and x<128 and y>=0 and y<64 then
    pico8.map[y][x]=v
  end
end

function fget(n, f)
  if n==nil then return nil end
  if f~=nil then
    -- return just that bit as a boolean
    if not pico8.spriteflags[flr(n)] then
      return false
    end
    return pico8.spriteflags[flr(n)] & (1 << flr(f)) ~= 0
  end
  return pico8.spriteflags[flr(n)] or 0
end

function fset(n, f, v)
  -- fset n [f] v
  -- f is the flag index 0..7
  -- v is boolean
  if v==nil then
    v, f = f, nil
  end
  if f then
    -- set specific bit to v (true or false)
    if v then
      pico8.spriteflags[n]=pico8.spriteflags[n] | (1 << f)
    else
      pico8.spriteflags[n]=pico8.spriteflags[n] & ~(1 << f)
    end
  else
    -- set bitfield to v (number)
    pico8.spriteflags[n]=v
  end
end

function sget(x, y)
  return 0
end

function sset(x, y, c)
end

function music(n, fadems, channel_mask)
  assert(n, "pico8 tolerates nil as 0, but we don't for clarity")
  if n < -1 then
    n = 0
  end
  if n >= 0 then
    -- simulate music currently played
    -- this will be correct for a looping music (without knowing the used channels and current play time)
    -- however for a non-looping music we won't detect when the music is supposed to end in integration tests
    fadems = fadems or 0
    channel_mask = channel_mask or 0
    pico8.current_music={music=n, fadems=fadems, channel_mask=channel_mask}
  else
    pico8.current_music = nil
  end
end

function sfx(n, channel, offset)
  -- most sfx are non-looping so it's not so useful to have a current sfx, and it's tedious
  -- to keep a list of played sfx history, so we just do nothing and will spy on sfx if needed
end

function peek(addr)
  return pico8.poked_addresses[addr] or 0
end

function poke(addr, val)
  pico8.poked_addresses[addr] = val
end

function peek2(addr)
  local val = 0
  val = val + peek(addr+0)
  val = val + peek(addr+1)*0x100
  return val
end

function poke2(addr, val)
  poke(addr+0, (val & 0x00ff) >> 0)
  poke(addr+1, (val & 0xff00) >> 8)
end

function peek4(addr)
  local val = 0
  val = val + peek(addr+0)/0x10000
  val = val + peek(addr+1)/0x100
  val = val + peek(addr+2)
  val = val + peek(addr+3)*0x100
  return val
end

function poke4(addr, val)
  val=val*0x10000
  poke(addr+0, (val & 0x000000ff) >>  0)
  poke(addr+1, (val & 0x0000ff00) >>  8)
  poke(addr+2, (val & 0x00ff0000) >> 16)
  poke(addr+3, (val & 0xff000000) >> 24)
end

function memcpy(dest_addr, source_addr, len)
  if len<1 or dest_addr==source_addr then
    return
  end

  -- screen hack (removed)

  local offset=dest_addr-source_addr
  if source_addr>dest_addr then
    for i=dest_addr, dest_addr+len-1 do
      poke(i, peek(i-offset))
    end
  else
    for i=dest_addr+len-1, dest_addr, -1 do
      poke(i, peek(i-offset))
    end
  end

  -- __scrimg and __scrblit (removed)
end

function memset(dest_addr, val, len)
  if len<1 then
    return
  end
  for i=dest_addr, dest_addr+len-1 do
    poke(i, val)
  end
end

function reload(dest_addr, source_addr, len, filename)
end

function cstore(dest_addr, source_addr, len, filename)
end

function rnd(x)
  if type(x) == "table" then
    return #x > 0 and x[math.random(#x)] or nil
  end
  return math.random()*(x or 1)
end

function srand(seed)
  math.randomseed(flr(seed*0x10000))
end

function flr(value)
  if value ~= nil then
    return math.floor(value)
  else
    return 0
  end
end

function ceil(value)
  if value ~= nil then
    return math.ceil(value)
  else
    return 0
  end
end

function sgn(x)
  return x<0 and-1 or 1
end

abs=math.abs

-- pico8 min only supports 2 arguments. use math.min if you want the min of 3+ arguments in busted tests
function min(a, b)
  if a==nil or b==nil then
    return 0
  end
  if a<b then return a end
  return b
end

-- pico8 max only supports 2 arguments. use math.max if you want the max of 3+ arguments in busted tests
function max(a, b)
  if a==nil or b==nil then
    return 0
  end
  if a>b then return a end
  return b
end

-- return value in the middle
-- can also be used for clamping
function mid(x, y, z)
  return (x<=y)and((y<=z)and y or((x<z)and z or x))or((x<=z)and x or((y<z)and z or y))
end

function cos(x)
  return math.cos((x or 0)*math.pi*2)
end

function sin(x)
  return-math.sin((x or 0)*math.pi*2)
end

sqrt=math.sqrt

function atan2(x, y)
  if x == 0 and y == 0 then
    return 0.25
  end
  return (-math.atan2(y, x) / (math.pi * 2)) % 1.0
end

-- Binary functions below have been superseded,
--  but we kept them for picotool and busted tests:
--  - p8tool currently fails to parse new 0.2 binary operators
--    (https://github.com/dansanderson/picotool/issues/70)
--  - busted will use native Lua's own float representation
--    giving different results in edge cases (hence the 0x10000 ops
--    below)
-- Since binary operators are more efficient and cost fewer tokens,
--  consider adding a conversion from b* functions to binary ops
--  in preprocess.py (maybe a simple regex if you don't need to
--  support brackets in brackets, for instance)

-- superseded by &
function band(x, y)
  return (x*0x10000 & y*0x10000)/0x10000
end

-- superseded by |
function bor(x, y)
  return (x*0x10000 | y*0x10000)/0x10000
end

-- superseded by ^^
function bxor(x, y)
  return (x*0x10000 ~ y*0x10000)/0x10000
end

-- superseded by ~
function bnot(x)
  return ~(x*0x10000)/0x10000
end

-- superseded by <<
function shl(x, y)
  return (x*0x10000 << y)/0x10000
end

-- superseded by >>
function shr(x, y)
  return bit.arshift(x*0x10000, y)/0x10000
end

-- superseded by >>>
function lshr(x, y)
  return (x*0x10000 >> y)/0x10000
end

-- superseded by <<>
function rotl(x, y)
  return bit.lrotate(x*0x10000, y)/0x10000
end

-- superseded by >><
function rotr(x, y)
  return bit.rrotate(x*0x10000, y)/0x10000
end

function time()
  -- starting pico8 0.1.12, time() returns time in seconds,
  --   dividing by the appropriate fps (30 or 60 if using _update/_update60 resp.)
  -- in busted, we only support 60 fps updates, so we just hardcoded the result
  -- note that _draw may still be called at 30fps, so using time() in draw would
  --   give different results in busted utests
  -- accessing gameapp.fps would be more correct, but we can't do that here
  --  so if you really want a settable fps, add a member pico8.fps
  return pico8.frames/60
end
t=time

function btn(i, p)
  if i~=nil or p~=nil then
    p=p or 0
    if p<0 or p>1 then
      return false
    end
    return not not pico8.keypressed[p][i]
  else
    local bits=0
    for i=0, 5 do
      bits=bits+(pico8.keypressed[0][i] and 2^i or 0)
      bits=bits+(pico8.keypressed[1][i] and 2^(i+8) or 0)
    end
    return bits
  end
end

function btnp(i, p)
  if i~=nil or p~=nil then
    p=p or 0
    if p<0 or p>1 then
      return false
    end
    local init=(pico8.fps/2-1)
    local v=pico8.keypressed.counter
    if pico8.keypressed[p][i] and (v==init or v==1) then
      return true
    end
    return false
  else
    local init=(pico8.fps/2-1)
    local v=pico8.keypressed.counter
    if not (v==init or v==1) then
      return 0
    end
    local bits=0
    for i=0, 5 do
      bits=bits+(pico8.keypressed[0][i] and 2^i or 0)
      bits=bits+(pico8.keypressed[1][i] and 2^(i+8) or 0)
    end
    return bits
  end
end

function cartdata(id)
end

function dget(index)
  index=flr(index)
  if index<0 or index>63 then
    -- out of range
    return nil
  end
  return pico8.cartdata[index]
end

function dset(index, value)
  index=flr(index)
  if index<0 or index>63 then
    -- out of range
    return
  end
  pico8.cartdata[index]=value
end

local tfield={[0]="year", "month", "day", "hour", "min", "sec"}
function stat(x)
  if x == 0 then
    return pico8.memory_usage
  elseif x == 1 then
    return pico8.total_cpu
  elseif x == 2 then
    return pico8.system_cpu
  elseif x == 4 then
    return pico8.clipboard
  elseif x == 7 then
    return pico8.fps
  elseif x == 8 then
    return pico8.fps
  elseif x == 9 then
    return pico8.fps
  elseif x >= 16 and x <= 23 then
    return 0  -- audio channels not supported
  elseif x == 30 then
    return 0  -- devkit keyboard not supported
  elseif x == 31 then
    return "" -- devkit keyboard not supported
  elseif x == 32 then
    return pico8.mousepos.x
  elseif x == 33 then
    return pico8.mousepos.y
  elseif x == 34 then
    local btns=0
    for i=0, 2 do
      if pico8.mousebtnpressed[i+1] then
        btns=btns | (1 << i)
      end
    end
    return btns
  elseif x == 36 then
    return pico8.mwheel
  elseif (x >= 80 and x <= 85) or (x >= 90 and x <= 95) then
    local tinfo
    if x < 90 then
      tinfo = os.date("!*t")
    else
      tinfo = os.date("*t")
    end
    return tinfo[tfield[x%10]]
  elseif x == 100 then
    return nil -- todo: breadcrumb not supported
  end
  return 0
end

function holdframe()
end

function ord(str, index)
  -- ord is very close to string.byte, except it doesn't take a range end as 3rd argument
  -- (se we prefer a full definition instead of setting ord = string.byte, but that could
  -- work too if we consider that passing extra args to ord is UB)
  -- As usual in PICO-8, it also supports nil arguments and even ignore arguments of the
  -- wrong type. But we consider this UB and prefer having an error in these cases,
  -- so we let string.byte handle it.
  return string.byte(str, index)
end

function chr(val)
  -- chr is very close to string.char, but it applies a modulo 256 to val
  -- it also returns "\0" in case of invalid argument, but we consider this UB
  return string.char(val % 256)
end

-- the functions below are very close to the native functions in Lua
-- note that they still differ in UB cases like not passing the right
-- argument type, but we do not mind (if we misuse the functions,
-- busted will simply detect invalid usage better than PICO-8)
sub=string.sub
cocreate=coroutine.create
coresume=coroutine.resume
yield=coroutine.yield
costatus=coroutine.status
-- traceback doesn't take arguments like a coroutine, so we must use it with xpcall
--  (see coroutine_runner)
trace=debug.traceback
pack=table.pack
unpack=table.unpack

-- the functions below are normally attached to the program code, but are here for simplicity
function all(a)
  -- pico8 may tolerate nil args in general, but it's error-prone so let busted detect issues
  assert(a)
  if a==nil or #a==0 then
    return function() end
  end
  local i, li=1
  return function()
    if (a[i]==li) then i=i+1 end
    while(a[i]==nil and i<=#a) do i=i+1 end
    li=a[i]
    return a[i]
  end
end

function foreach(a, f)
  for v in all(a) do
    f(v)
  end
end

function count(a)
  local count=0
  for i=1, #a do
    if a[i]~=nil then count=count+1 end
  end
  return count
end

function add(a, v, i)
  -- pico8 doesn't do anything if `a` is empty, but to help debugging in utests,
  --  we assert instead. so don't rely on the pico8 behavior in production to avoid
  --  divergence with busted.
  assert(a ~= nil, "cannot add to nil table")
  i = i or #a+1
  -- note parameter inversion in table.insert compared to add
  -- (but only when there are 3 arguments) that prevents us from doing add = table.insert
  table.insert(a, i, v)
end

function del(a, dv)
  if a==nil then return end
  for i=1, #a do
    if a[i]==dv then
      table.remove(a, i)
      return
    end
  end
end

-- pico8 0.2.1
function deli(a, i)
  table.remove(a, i)
end

-- pico8 0.2.1b
-- TODO: add split and replace usages of strspl, then stop including strspl in projects if possible

-- printh function must not refer to the native print directly (no printh = print)
--   because params are different and to avoid spying on
--   the wrong calls (busted -o tap may print natively)
-- exceptionally, we add a custom parameter `log_dirname`
--   to make it easier to test this function itself in busted
-- in PICO-8, the log directory is always [pico-8 system dir on your OS]/carts
function printh(str, file_basename, overwrite, log_dirname)
  if not log_dirname then
    log_dirname = "log"
  end

  -- file writing is not supported in tests
  if file_basename then
    -- if log directory doesn't exist, create it
    local log_dir_attr = lfs.attributes(log_dirname)
    if not log_dir_attr then
      lfs.mkdir(log_dirname)
    else
      assert(log_dir_attr.mode == "directory", "'"..log_dirname.."' is not a directory but a "..log_dir_attr.mode)
    end

    local mode = overwrite and "w" or "a"
    -- when running in busted, put the logs in a log folder
    --   and add the .txt extension (instead of .p8l)
    --   for better organization
    local log_filepath = log_dirname.."/"..file_basename..".txt"
    local file = io.open(log_filepath, mode)
    file:write(str, "\n")
    file:close()
  else
    print(str)
  end
end

api = {}

-- only print is defined under api to avoid overriding native print
-- (used by busted -o tap)
-- note that runtime code will need to define api.print
function api.print(str, ...)
  local extra_nargs = select('#', ...)
  if extra_nargs > 1 then
    -- signature: str, x, y, col
    x, y, col = ...
  else
    -- signature: str, col
    col = ...
  end
  if col then
    color(col)
  end
end

-- empty implementation to avoid errors when calling menuitem in utests without stub
function menuitem(index, label, callback)
end

-- Empty implementation:
--  extcmd tends to deal with system and therefore difficult to meaningfully
--  emulate for testing. Or we'd need to track many variables like window title...
-- In general, we recommend stubbing extcmd in every test on a function using it,
--  to assert.spy on it. But in case we don't, the empty implementation avoids crashing at least.
function extcmd(cmd_name, ...)
end

function load(cartridge_path)
  -- print what is loaded to easier utest / headless itest debug
  -- you're supposed to stub load every time you encounter it in utests, so at least it will help spot that
  -- in headless itests, it will simply help detecting when we're supposed to change cartridge, which does
  --  nothing otherwise (we'd need to restart a new app corresponding to the new cartridge...)
  print("load cartridge: "..cartridge_path)
end

--(busted)
--#endif
