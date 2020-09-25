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
