local outline = {}

-- print `text` at (x, y) with internal color `col` and outline color `outline_col`
-- if `outline_col` is falsy, outlining is skipped
function outline.print_with_outline(text, x, y, col, outline_col)
  if outline_col then
    -- draw outline with 4 shadows of offset 1 in every cardinal direction
    -- the trick to avoid 4 separate calls is to mentally rotate the shape by 45 degrees,
    --  so the 4 offsets are the 4 corners of a square
    -- cross iterate on those diagonals offsets known as du and dv, then use a rotation matrix
    --  + scaling to come back to dx and dy as -1, 0 or +1
    for du = -1, 1, 2 do
      for dv = -1, 1, 2 do
        local dx = (du + dv) / 2
        local dy = (du - dv) / 2
        api.print(text, x + dx, y + dy, outline_col)
      end
    end
  end
  api.print(text, x, y, col)
end

return outline
