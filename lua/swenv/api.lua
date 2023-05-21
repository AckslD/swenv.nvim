local M = {}

local settings = require('swenv.config').settings

local ORIGINAL_PATH = vim.fn.getenv('PATH')

local current_venv = nil

local update_path = function(path)
  vim.fn.setenv('PATH', path .. '/bin' .. ':' .. ORIGINAL_PATH)
end

local set_venv = function(venv)
  if venv.source == 'conda' or venv.source == 'micromamba' then
    vim.fn.setenv('CONDA_PREFIX', venv.path)
    vim.fn.setenv('CONDA_DEFAULT_ENV', venv.name)
    vim.fn.setenv('CONDA_PROMPT_MODIFIER', '(' .. venv.name .. ')')
  else
    vim.fn.setenv('VIRTUAL_ENV', venv.path)
  end

  current_venv = venv
  -- TODO: remove old path
  update_path(venv.path)

  if settings.post_set_venv then
    settings.post_set_venv(venv)
  end
end

---
---Checks who appears first in PATH. Returns `true` if `first` appears first and `false` otherwise
---
---@param first string|nil
---@param second string|nil
---@return boolean
local has_high_priority_in_path = function (first, second)
  if first == nil or first == vim.NIL then
    return false
  end

  if second == nil or second == vim.NIL then
    return true
  end

  return string.find(ORIGINAL_PATH, first) < string.find(ORIGINAL_PATH, second)
end

M.init = function()
  local success, Path = pcall(require, 'plenary.path')
  if not success then
    vim.notify('Could not require plenary: ' .. Path, vim.log.levels.WARN)
    return
  end
  local venv

  local venv_env = vim.fn.getenv('VIRTUAL_ENV')
  if venv_env ~= vim.NIL then
    venv = {
      name = Path:new(venv_env):make_relative(settings.venvs_path),
      path = venv_env,
      source = 'venv',
    }
  end

  local conda_env = vim.fn.getenv('CONDA_DEFAULT_ENV')
  if conda_env ~= vim.NIL and has_high_priority_in_path(conda_env, venv_env) then
    venv = {
      name = conda_env,
      path = vim.fn.getenv('CONDA_PREFIX'),
      source = 'conda'
    }
  end

  if venv then
    current_venv = venv
  end
end

M.get_current_venv = function()
  return current_venv
end

M.get_venvs = function(venvs_path)
  local success, Path = pcall(require, 'plenary.path')
  if not success then
    vim.notify('Could not require plenary: ' .. Path, vim.log.levels.WARN)
    return
  end
  local scan_dir = require('plenary.scandir').scan_dir

  local venvs = {}
  
  -- CONDA
  local conda_exe = vim.fn.getenv('CONDA_EXE')
  if conda_exe ~= vim.NIL then
    local conda_env_path = Path:new(conda_exe):parent():parent() .. '/envs'
    local conda_paths = scan_dir(conda_env_path, { depth = 1, only_dirs = true, silent = true })

    for _, path in ipairs(conda_paths) do
      table.insert(venvs, {
        name = Path:new(path):make_relative(conda_env_path),
        path = path,
        source = 'conda',
      })
    end
  end
  
  --MICROMAMBA
  local micromamba_exe = vim.fn.getenv('MAMBA_EXE')
  if micromamba_exe ~= vim.NIL then
    local micromamba_env_path = Path:new(vim.fn.getenv('MAMBA_ROOT_PREFIX')) .. '/envs'
    local micromamba_paths = scan_dir(micromamba_env_path, { depth = 1, only_dirs = true, silent = true })

    for _, path in ipairs(micromamba_paths) do
      table.insert(venvs, {
        name = Path:new(path):make_relative(micromamba_env_path),
        path = path,
        source = 'micromamba',
      })
    end
  end

  -- VENV
  local paths = scan_dir(venvs_path, { depth = 1, only_dirs = true, silent = true })
  for _, path in ipairs(paths) do
    table.insert(venvs, {
      -- TODO how does one get the name of the file directly?
      name = Path:new(path):make_relative(venvs_path),
      path = path,
      source = 'venv',
    })
  end

  return venvs
end

M.pick_venv = function()
  vim.ui.select(settings.get_venvs(settings.venvs_path), {
    prompt = 'Select python venv',
    format_item = function(item)
      return string.format('%s (%s) [%s]', item.name, item.path, item.source)
    end,
  }, function(choice)
    if not choice then
      return
    end
    set_venv(choice)
  end)
end

return M
