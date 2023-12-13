local M = {}

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
      matrix[i][j] = math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
    end
  end
  return matrix[len1][len2]
end

-- Function to find the best match based on Levenshtein distance
M.best_match = function(items, query)
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

return M
