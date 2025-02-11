# swenv.nvim

Tiny plugin to quickly switch python virtual environments from within neovim without
restarting.

![gscreenshot_2022-09-19-144438](https://user-images.githubusercontent.com/23341710/191020632-543e8118-4eea-4964-8d59-1556836b929f.png)

## Installation

For example using [`packer`](https://github.com/wbthomason/packer.nvim):

```lua
use 'AckslD/swenv.nvim'
```

Requires `plenary`.

## Usage

### Pick Env

Call

```lua
require('swenv.api').pick_venv()
```

to pick an environment. Uses `vim.ui.select` so a tip is to use eg
[dressing.nvim](https://github.com/stevearc/dressing.nvim).

### Get Environment

To show the current venv in for example a status-line you can call

```lua
require('swenv.api').get_current_venv()
```

### Set Environment

Using a [fuzzy search](https://en.wikipedia.org/wiki/Approximate_string_matching) you
can set the environment to the best match.

```lua
require('swenv.api').set_venv('venv_fuzzy_name')
```

### Auto Environment

```lua
require('swenv.api').auto_venv()
```

Using a file named **.venv** in your projects root folder, it will automatically set the
virtual-env for such environment.

#### project.nvim

With [project_nvim](https://github.com/ahmedkhalf/project.nvim) installed swenv.nvim will activate in-project venvs if present.

This integration is skipped if `auto_create_venv` is enabled

#### Auto Create venv

You can have swenv.nvim attempt to create a venv directory and set to it.

swenv.nvim will search up for a file containing dependencies and create a new venv directory set to `auto_create_venv_dir`

Supported install types in order:

- `pdm sync` with `pdm.lock` (does not modify pdm settings. You need to set the venv directory in pdm)

> These require the `venv` module in python:

- `pip install` with `requirements.txt`
- `pip install` with `dev-requirements.txt` (preferred over requirements.txt)
- `pip install` with `pyproject.toml`

```lua

require('swenv').setup({
    -- attempt to auto create and set a venv from dependencies
    auto_create_venv = true,
    -- name of venv directory to create if using pip
    auto_create_venv_dir = ".venv"
})

```

#### Auto Command

**Vimscript**:

```vimscript
autocmd FileType python lua require('swenv.api').auto_venv()
```

**Lua**:

```lua
vim.api.nvim_create_autocmd("FileType", {
    pattern = {"python"},
    callback = function()
        require('swenv.api').auto_venv()
    end
})
```

#### Reset Environment

To reset the virtual environment and restore the original Python version, you can call:

```lua
require('swenv.api').reset_venv()
```

## Configuration

Pass a dictionary into `require("swenv").setup()` with callback functions. These are the
defaults:

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
  -- Something to do after setting an environment, for example call vim.cmd.LspRestart
  post_set_venv = nil,
})
```

### Reload LSP client on setting venv

You can get your lsp client by name and reload the client after setting the venv.

```lua
post_set_venv = function()
  local client = vim.lsp.get_clients({ name = "basedpyright" })[1]
  if not client then
    return
  end
  local venv = require("swenv.api").get_current_venv()
  if not venv then
    return
  end
  local venv_python = venv.path .. "/bin/python"
  if client.settings then
    client.settings = vim.tbl_deep_extend("force", client.settings, { python = { pythonPath = venv_python } })
  else
    client.config.settings =
        vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = venv_python } })
  end
  client.notify("workspace/didChangeConfiguration", { settings = nil })
end,
```

### Lualine Component

For `lualine` there is already a configured component called `swenv`. It displays an
icon and the name of the activated environment.

#### Lualine Usage

Add this to your `lualine` sections to use the component

```lua
sections = {
    ...
    lualine_a = 'swenv' -- uses default options
    lualine_x = { 'swenv', icon = '<icon>' } -- passing lualine component options
    ...
}
```

These are the defaults options:

```lua
{
  icon = "",
  color = { fg = "#8fb55e" },
}
```

Only show the section if the file types match python

```lua
{
    "swenv",
    cond = function()
        return vim.bo.filetype == "python"
    end,
}
```

#### Issues

##### coc.nvim

`post_set_venv` fails with `coc.nvim`, since coc loads before we set environment.

As a quick fix, use a timer:

```lua
swenv.setup({
    post_set_venv = function()
        local timer = vim.loop.new_timer()
        -- Check every 250ms if g:coc_status exists
        timer:start(250, 250, vim.schedule_wrap(function()
            if vim.g.coc_status then
                timer:stop()
                vim.cmd([[:CocRestart]])
            end
        end))
    end
})
```
