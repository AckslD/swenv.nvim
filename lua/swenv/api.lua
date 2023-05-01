local M = {}

local settings = require('swenv.config').settings

local ORIGINAL_PATH = vim.fn.getenv('PATH')

local current_venv = nil

local get_conda_base = function(conda_exe_path)
  local parts = {}

  for part in conda_exe_path:gmatch('[^/]+') do
    table.insert(parts, part)
  end
  table.remove(parts) -- remove the last part
  table.remove(parts) -- remove the second-to-last part
  return '/' .. table.concat(parts, '/')
end

local set_venv = function(venv)
  if venv.source == 'conda' then
    vim.fn.setenv('CONDA_PREFIX', venv.path)
    vim.fn.setenv('CONDA_DEFAULT_ENV', venv.name)
    vim.fn.setenv('CONDA_PROMPT_MODIFIER', '(' .. venv.name .. ')')
    vim.cmd('LspRestart')
    -- TODO: remove old path
    vim.fn.setenv('PATH', venv.path .. '/bin' .. ':' .. ORIGINAL_PATH)
  else
    current_venv = venv
    local venv_bin_path = venv.path .. '/bin'
    vim.fn.setenv('PATH', venv_bin_path .. ':' .. ORIGINAL_PATH)
    vim.fn.setenv('VIRTUAL_ENV', venv.path)
    if settings.post_set_venv then
      settings.post_set_venv(venv)
    end
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
  local conda_base_path = get_conda_base(vim.fn.getenv('CONDA_EXE'))
  local conda_paths = scan_dir(conda_base_path .. '/envs', { depth = 1, only_dirs = true, silent = true })

  for _, path in ipairs(conda_paths) do
    table.insert(venvs, {
      name = Path:new(path):make_relative(conda_base_path .. '/envs'),
      path = path,
      source = 'conda',
    })
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
