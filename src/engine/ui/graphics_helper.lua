local graphics_helper = {}

-- draw a box between x0, y0, x1 and y1 (bottom to top and right to left arguments are supported)
function graphics_helper.draw_box(x0, y0, x1, y1, border_color, fill_color)
  -- if coordinates are not top to bottom and left to right, swap them so our calculations with fill are correct
  if x0 > x1 then
    local x = x0
    x0 = x1
    x1 = x
  end
  if y0 > y1 then
    local y = y0
    y0 = y1
    y1 = y
  end

  -- draw border
  rect(x0, y0, x1, y1, border_color)

  -- fill rectangle if big enough to have an interior
  if x0 + 1 <= x1 - 1 and y0 + 1 <= y1 - 1 then
    rectfill(x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill_color)
  end
end

-- draw a rounded box between x0, y0, x1 and y1 (bottom to top and right to left arguments are supported)
-- only 1 pixel is removed from each corner
function graphics_helper.draw_rounded_box(x0, y0, x1, y1, border_color, fill_color)
  -- if coordinates are not top to bottom and left to right, swap them so our calculations with fill are correct
  if x0 > x1 then
    local x = x0
    x0 = x1
    x1 = x
  end
  if y0 > y1 then
    local y = y0
    y0 = y1
    y1 = y
  end

  -- draw border, cutting corners
  line(x0 + 1, y0, x1 - 1, y0, border_color)
  line(x1, y0 + 1, x1, y1 - 1, border_color)
  line(x1 - 1, y1, x0 + 1, y1, border_color)
  line(x0, y1 - 1, x0, y0 + 1, border_color)

  -- fill rectangle if big enough to have an interior
  if x0 + 1 <= x1 - 1 and y0 + 1 <= y1 - 1 then
    rectfill(x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill_color)
  end
end

-- draw a gauge with frame between x0, y0, x1 and y1 (bottom to top and right to left arguments are supported)
--   with a given fill ratio, filled toward given direction: directions
function graphics_helper.draw_gauge(x0, y0, x1, y1, fill_ratio, fill_direction, border_color, background_color, fill_color)
  -- if coordinates are not top to bottom and left to right, swap them so our calculations with fill are correct
  if x0 > x1 then
    local x = x0
    x0 = x1
    x1 = x
  end
  if y0 > y1 then
    local y = y0
    y0 = y1
    y1 = y
  end

  -- draw border
  rect(x0, y0, x1, y1, border_color)

  -- fill rectangle if big enough to have an interior
  if x0 + 1 <= x1 - 1 and y0 + 1 <= y1 - 1 then
    rectfill(x0 + 1, y0 + 1, x1 - 1, y1 - 1, background_color)

    if fill_direction == directions.left or fill_direction == directions.right then
      local gauge_width = flr(fill_ratio * (x1 - x0 - 1))  -- padding of 1px each side
      if gauge_width >= 1 then
        if fill_direction == directions.right then
          rectfill(x0 + 1, y0 + 1, x0 + gauge_width, y1 - 1, fill_color)
        else  -- fill_direction == directions.left
          rectfill(x1 - gauge_width, y0 + 1, x1 - 1, y1 - 1, fill_color)
        end
      end
    else  -- vertical direction
      local gauge_height = flr(fill_ratio * (y1 - y0 - 1))  -- padding of 1px each side
      if gauge_height >= 1 then
        if fill_direction == directions.down then
          rectfill(x0 + 1, y0 + 1, x1 - 1, y0 + gauge_height, fill_color)
        else  -- fill_direction == directions.up
          rectfill(x0 + 1, y1 - gauge_height, x1 - 1, y1 - 1, fill_color)
        end
      end
    end
  end
end

return graphics_helper
