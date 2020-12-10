require("engine/test/bustedhelper")
require("engine/render/sprite")  -- already in engine/common, but added for clarity

describe('spr_r', function ()

  -- it's a bit hard to do a display simulation with 128x128
  --  so just work on 16x16; not quite enough to contain any rotated sprite of 8x16,
  --  but with the right pivot you can make it fit somewhat
  -- note that pixels drawn outside the screen matrix should be ignored
  local screen_matrix_reduced_size = 16

  -- simulated screen pixel matrix initialization
  local screen_matrix = {}
  for j = 1, screen_matrix_reduced_size do
    local row = {}
    for i = 1, screen_matrix_reduced_size do
      add(row, 0)
    end
    add(screen_matrix, row)
  end

  -- simulated spritesheet source, 8x16 for a non-symmetrical case
  local spritesheet = {
    {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1},
    {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
    {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
    {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1},
    {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0},
    {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0},
    {0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 1, 5, 5, 5, 1, 5, 5, 5, 5},
    {0, 0, 0, 0, 0, 0, 0, 1, 5, 5, 5, 1, 5, 5, 5, 5},
    {0, 0, 0, 0, 0, 0, 0, 1, 5, 5, 5, 1, 5, 5, 5, 5},
    {0, 0, 0, 0, 0, 0, 0, 1, 5, 5, 1, 5, 5, 1, 5, 5},
    {0, 0, 0, 0, 0, 0, 0, 1, 5, 1, 5, 5, 5, 5, 1, 5},
    {0, 0, 0, 0, 0, 0, 0, 1, 5, 1, 5, 5, 5, 5, 1, 5},
    {0, 0, 0, 0, 0, 0, 0, 1, 5, 5, 1, 5, 5, 1, 5, 5},
    {1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 5, 1, 1, 5, 5, 5}
  }

  local function dump_matrix(sequence)
    -- dump_sequence only handles one level of sequence, so to handle two of them,
    --  we adapted dump_sequence by adding more \n and replace nice_dump
    --  with another dump_sequence: we can now visualize the matrix to debug each test
    --  since are_same is really not good to show multi-dimensional sequences
    return "{\n"..joinstr_table(", \n", sequence, dump_sequence).."\n}"
  end

  setup(function ()
    stub(_G, "sget", function (sx, sy)
      sx = flr(sx)
      sy = flr(sy)
      return spritesheet[sy+1][sx+1]
    end)
    stub(_G, "pset", function (x, y, c)
      x = flr(x)
      y = flr(y)
      if x >= 0 and x < screen_matrix_reduced_size and
          y >= 0 and y < screen_matrix_reduced_size then
        screen_matrix[y+1][x+1] = c
      end
    end)
    -- just to compare spr and spr_r and check API compatibility
    stub(_G, "spr", function (n, x, y, w, h, flip_x, flip_y)
      -- w and h do not default to 1 to simplify, make sure to pass them
      -- flip_x and flip_y not supported
      local j = n // 16
      local i = n % 16
      local sx = tile_size * i
      local sy = tile_size * j
      local sw = tile_size * w
      local sh = tile_size * h
      for dx = 0, sw - 1 do
        for dy = 0, sh - 1 do
          local c = sget(sx + dx, sy + dy)
          -- black always transparent when using spr in this test
          if c ~= 0 then
            pset(x + dx, y + dy, c)
          end
        end
      end
    end)
  end)

  teardown(function ()
    sget:revert()
    pset:revert()
    spr:revert()
  end)

  before_each(function ()
    -- reset screen matrix
    for j = 1, screen_matrix_reduced_size do
      for i = 1, screen_matrix_reduced_size do
        screen_matrix[j][i] = 0
      end
    end
  end)

  after_each(function ()
    sget:clear()
    pset:clear()
    spr:clear()
  end)

  -- it's a test on spr, but only to check it's equivalent to spr_r when converting n <-> (i, j)
  --  and angle = 0
  it('should draw a sprite (0, 0) as the original at (0, 0) when angle is 0 (where pivot is)', function ()
    spr(0, 0, 0, 1, 1)

    -- uncomment for better debug
    -- printh("screen_matrix: "..dump_matrix(screen_matrix))

    assert.are_same({
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    }, screen_matrix)
  end)

  -- predicting non-square angles is a bit difficult so we only check rotations multiple of 0.25

  it('should draw a sprite (0, 0) as the original at (0, 0) when angle is 0 (where pivot is)', function ()
    spr_r(0, 0, 0, 0, 1, 1, false, false, 0, 0, 0, color_to_bitmask(0))

    -- printh("screen_matrix: "..dump_matrix(screen_matrix))

    assert.are_same({
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    }, screen_matrix)
  end)

  it('should draw a sprite (0, 0) with pivot (8, 8) at (8, 0) rotated around pivot (4, 4) by 90 degrees counter-clockwise when angle is 0.25', function ()
    spr_r(0, 0, 4, 4, 1, 1, false, false, 4, 4, 0.25, color_to_bitmask(0))

    -- printh("screen_matrix: "..dump_matrix(screen_matrix))

    assert.are_same({
      {0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    }, screen_matrix)
  end)

  it('draw a sprite (0, 0) flipped horizontally around pivot (4, 4) when flip_x is true', function ()
    spr_r(0, 0, 4, 4, 1, 1, true, false, 4, 4, 0, color_to_bitmask(0))

    -- printh("screen_matrix: "..dump_matrix(screen_matrix))

    assert.are_same({
      {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    }, screen_matrix)
  end)

  it('should draw a sprite (0, 0) span (1, 2) flipped vertically around pivot (0, 8) when flip_y is true', function ()
    spr_r(0, 0, 0, 8, 1, 2, false, true, 0, 8, 0, color_to_bitmask(0))

    -- printh("screen_matrix: "..dump_matrix(screen_matrix))

    assert.are_same({
      {1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    }, screen_matrix)
  end)

  it('should draw a sprite (0, 0) span (2, 1) flipped horizontally and rotated around pivot (8, 4) by 90 degrees clockwise at (4, 8) when flip_x is true and angle is 0.75', function ()
    spr_r(0, 0, 4, 8, 2, 1, true, false, 8, 4, 0.75, color_to_bitmask(0))

    -- printh("screen_matrix: "..dump_matrix(screen_matrix))

    assert.are_same({
      {0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0}
    }, screen_matrix)
  end)

  it('should draw a sprite (1, 1) ignoring transparent color 5', function ()
    spr_r(1, 1, 8, 8, 1, 1, false, false, 0, 0, 0, color_to_bitmask(5))

    -- printh("screen_matrix: "..dump_matrix(screen_matrix))

    assert.are_same({
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0}
    }, screen_matrix)
  end)

end)
