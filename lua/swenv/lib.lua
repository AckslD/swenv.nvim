-- Function for computing the Levenshtein distance (fuzzy search)
local function lev(str1, str2)
  local len1, len2 = #str1, #str2
  local matrix = {}
  for i = 0, len1 do
    matrix[i] = { [0] = i }
  end
  for j = 0, len2 do
    matrix[0][j] = j
  end
  for i = 1, len1 do
    for j = 1, len2 do
      local cost = str1:byte(i) == str2:byte(j) and 0 or 1
      matrix[i][j] = math.min(
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost
      )
    end
  end
  return matrix[len1][len2]
end

-- Function to find the best match based on Levenshtein distance
local function best_match(items, query)
  local min_distance = math.huge -- Initialize minimum distance as infinity
  local match = nil -- Initialize match as nil to handle case if no match found
  for _, item in ipairs(items) do -- Iterate over items
    local distance = lev(query, item.name) -- Compute Levenshtein distance to the query
    if distance < min_distance then -- If this item is closer to query...
      min_distance = distance -- Update minimum distance
      match = item -- Update the match
    end
  end
  return match -- Return the best match
end

-- Get the name from a `.venv` file in the project root directory.
local function read_venv_name(project_dir)
  local file = io.open(project_dir .. "/.venv", "r") -- r read mode
  if not file then
    return nil
  end
  local content = file:read("*a") -- *a or *all reads the whole file
  file:close()
  return content:match("^%s*(.-)%s*$") -- Trim whitespace
end

return {
  best_match = best_match,
  read_venv_name = read_venv_name,
}
