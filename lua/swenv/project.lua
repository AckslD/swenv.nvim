local M = {}

M.get_local_venv_path = function(project_dir)
  return project_dir .. '/.venv'
end

-- Get the name from a `.venv` file in the project root directory.
M.read_venv_name_in_project = function(project_dir)
  -- local in-project pyenv environment
  local abs_venv_path = M.get_local_venv_path(project_dir)
  local venv_file = io.open(abs_venv_path, 'r') -- r read mode
  if not venv_file then
    return nil
  end

  local pyenv_cfg = io.open(abs_venv_path .. '/pyvenv.cfg')
  if not pyenv_cfg then
    return nil
  end
  for line in pyenv_cfg:lines() do
    local match = line:match('^prompt%s*=%s*(.*)')
    if match then
      local env_name = match
      pyenv_cfg:close()
      return env_name
    end
  end
end

M.read_venv_name_common_dir = function(project_dir)
  -- centralized environment
  local abs_venv_path = M.get_local_venv_path(project_dir)
  local venv_file = io.open(abs_venv_path, 'r') -- r read mode
  if not venv_file then
    return nil
  end
  local content = venv_file:read('*a') -- *a or *all reads the whole file
  if not content then
    return nil
  end
  local env_name = content:match('^%s*(.-)%s*$') -- Trim whitespace

  venv_file:close()
  return env_name
end

return M
