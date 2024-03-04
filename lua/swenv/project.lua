local M = {}
local Path = require('plenary.path')

local function isdir(dir_path)
  local f = io.popen('[ -d "' .. dir_path .. '" ] && echo -n y')
  local result = f:read(1)
  f:close()
  return result == "y"
end

local function get_local_env(venv_path)
  local venv_cfg = io.open(venv_path .. '/pyvenv.cfg', 'r')
  if not venv_cfg then
    print('no file: ' .. venv_path .. '/pyvenv.cfg')
    return nil
  end

  
  local configText = venv_cfg:read('*a') -- *a or *all reads the whole file
  local pattern = "prompt%s*=%s*([%w_]+)"
  local venv_name = configText:match(pattern)

  local venv = {
    name = venv_name,
    path = venv_path,
    source = 'local',
  }
  return venv
end

-- Get the name from a `.venv` file in the project root directory.
M.get_project_venv_data = function(project_dir)
  local venv_path = project_dir .. '/.venv'
  local file = io.open(venv_path, 'r') -- r read mode
  if isdir(venv_path) then
    return get_local_env(venv_path)
  end
  if not file then
    if isdir(venv_path) then
      return get_local_env(venv_path)
    end
    return nil
  end
  print('isdir for ' .. venv_path .. ' is ' .. tostring(isdir(venv_path)))
  
  local content = file:read('*a') -- *a or *all reads the whole file
  file:close()
  return content:match('^%s*(.-)%s*$') -- Trim whitespace
end

return M
