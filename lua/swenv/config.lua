local M = {}

M.settings = {
  -- Should return a list of tables with a `name` and a `path` entry each.
  -- Gets the argument `venvs_path` set below.
  -- By default just lists the entries in `venvs_path`.
  get_venvs = function(venvs_path)
    return require('swenv.api').get_venvs(venvs_path)
  end,
  -- Path passed to `get_venvs`.
  venvs_path = vim.fn.expand('~/venvs'),
  -- Something to do after setting an environment
  post_set_venv = nil,
  -- Attempt detect and auto create venv directories using
  -- pdm
  -- requirements.txt
  -- dev-requirements.txt
  -- pyproject.toml
  auto_create_venv = false,
  -- directory to create for venv auto creation
  auto_create_venv_dir = '.venv',
}

return M
