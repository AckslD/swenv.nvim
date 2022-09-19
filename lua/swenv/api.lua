local M = {}

local settings = require('swenv.config').settings

local ORIGINAL_PATH = vim.fn.getenv('PATH')

local current_venv = nil

local set_venv = function(venv)
  current_venv = venv
  local venv_bin_path = venv.path .. '/bin'
  vim.fn.setenv('PATH', venv_bin_path .. ':' .. ORIGINAL_PATH)
  vim.fn.setenv('VIRTUAL_ENV', venv.path)
  if settings.post_set_venv then
    settings.post_set_venv(venv)
  end
end

M.get_current_venv = function()
  return current_venv
end

M.get_venvs = function(venvs_path)
  local success, Path = pcall(require, 'plenary.path')
  if not success then
    vim.notify('Could not require plenary: '..Path, vim.log.levels.WARN)
    return
  end
  local scan_dir = require('plenary.scandir').scan_dir

  local paths = scan_dir(venvs_path, {depth = 1, only_dirs =true})
  local venvs = {}
  for _, path in ipairs(paths) do
    table.insert(venvs, {
      -- TODO how does one get the name of the file directly?
      name = Path:new(path):make_relative(venvs_path),
      path = path,
    })
  end
  return venvs
end

M.pick_venv = function()
  vim.ui.select(settings.get_venvs(settings.venvs_path), {
    prompt = 'Select python venv',
    format_item = function(item) return string.format('%s (%s)', item.name, item.path) end,
  }, function(choice)
    if not choice then
      return
    end
    set_venv(choice)
  end)
end

return M
