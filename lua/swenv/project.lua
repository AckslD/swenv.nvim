local M = {}

M.get_local_venv_path = function(project_dir)
  local abs_venv_path = project_dir .. '/.venv'
  return abs_venv_path
end

-- Get the name from a `.venv` file in the project root directory.
M.read_venv_name = function(project_dir)
  local abs_venv_path = M.get_local_venv_path(project_dir)
  local venv_file = io.open(abs_venv_path, 'r') -- r read mode
  if not venv_file then
    return nil
  end

  -- local in-project pyenv environment
  local env_name = nil
  local pyenv_cfg = io.open(abs_venv_path .. '/pyvenv.cfg')
  if pyenv_cfg then
    for line in pyenv_cfg:lines() do
      local match = line:match('^prompt%s*=%s*(.*)')
      if match then
        env_name = match
      end
    end
    pyenv_cfg:close()
  end

  -- centralized environment
  if not env_name then
    local content = venv_file:read('*a') -- *a or *all reads the whole file
    if content == nil then
      return nil
    end
    env_name = content:match('^%s*(.-)%s*$') -- Trim whitespace
  end

  venv_file:close()
  return env_name
end

return M
