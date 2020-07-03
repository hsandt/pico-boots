require("engine/core/math")

function mirror_dir_x(direction)
  if direction == directions.left then
    return directions.right
  elseif direction == directions.right then
    return directions.left
  else
    return direction
  end
end

function mirror_dir_y(direction)
  if direction == directions.up then
    return directions.down
  elseif direction == directions.down then
    return directions.up
  else
    return direction
  end
end

function rotate_dir_90_cw(direction)
  return (direction + 1) % 4
end

function rotate_dir_90_ccw(direction)
  return (direction - 1) % 4
end
