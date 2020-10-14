-- merge t2 into t1
-- ! if keys are duplicate, the entry will be overwritten with the value in t2,
--   even if it was a table (no deep merging)
function merge(t1, t2)
  for key, value in pairs(t2) do
    t1[key] = value
  end
end
