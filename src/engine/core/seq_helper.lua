-- return index of first element verifying condition_func
--  in seq, or nil if no such element is found
function seq_find_condition(seq, condition_func)
  -- unlike ipairs, all goes past [nil] in a sequence,
  --  so prefer all + manual index increment
  local index = 0
  for value in all(seq) do
    index = index + 1
    if condition_func(value) then
      return index
    end
  end
  return nil
end

-- return true if searched_value is contained in passed sequence
--  this uses any custom equality defined on the values
function seq_contains(seq, searched_value)
  for value in all(seq) do
    if value == searched_value then
      return true
    end
  end
  return false
end

-- return a copy of a sequence
--  (needs to be a proper sequence, nil in the middle will mess up indices)
function copy_seq(seq)
  local copied_seq = {}
  for value in all(seq) do
    add(copied_seq, value)
  end
  return copied_seq
end

-- filter a sequence following a condition function
--  (needs to be a proper sequence, nil in the middle will mess up indices)
function filter(seq, condition_func)
  local filtered_seq = {}
  for value in all(seq) do
    if condition_func(value) then
      add(filtered_seq, value)
    end
  end
  return filtered_seq
end
