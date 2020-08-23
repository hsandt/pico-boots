-- function decorator to create a function that receives
-- a sequence of arguments and unpacks it for the decorated function
function unpacking(f)
  return function (args)
    return f(unpack(args))
  end
end
