-- create an enum from a sequence of variant names
-- Minification warning: this won't support aggressive minification
--   unless all variants start with "_", or enum variants are always accessed
--   with my_enum["key"] or my_enum[key], since table keys are dynamically defined
function enum(variant_names)
  local t = {}
  local i = 1

  for variant_name in all(variant_names) do
    t[variant_name] = i
    i = i + 1
  end

  return t
end
