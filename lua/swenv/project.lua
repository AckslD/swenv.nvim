local M = {}

-- Get the name from a `.venv` file in the project root directory.
M.read_venv_name = function(project_dir)
  local file = io.open(project_dir .. '/.venv', 'r') -- r read mode
  if not file then
    return nil
  end
  local content = file:read('*a') -- *a or *all reads the whole file
  if content == nil then
    return nil
  end
  file:close()
  return content:match('^%s*(.-)%s*$') -- Trim whitespace
end

return M
