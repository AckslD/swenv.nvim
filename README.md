# swenv.nvim
Tiny plugin to quickly switch python virtual environments from within neovim without restarting.

![gscreenshot_2022-09-19-144438](https://user-images.githubusercontent.com/23341710/191020632-543e8118-4eea-4964-8d59-1556836b929f.png)

## Installation
For example using [`packer`](https://github.com/wbthomason/packer.nvim):
```lua
use {
  'AckslD/swenv.nvim',
  config = 'require("swenv").setup()',
}
```

## Usage
Call
```lua
require('swenv.api').pick_venv()
```
to pick an environment. Uses `vim.ui.select` so a tip is to use eg [dressing.nvim](https://github.com/stevearc/dressing.nvim).

To show the current venv in for example a status-line you can call
```lua
require('swenv.api').get_current_venv()
```

For `lualine` there is already a configured component called `swenv`.

## Configuration
Pass a dictionary into `require("swenv").setup()` with callback functions.
These are the defaults:
```lua
require('swenv').setup({
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
})
```
