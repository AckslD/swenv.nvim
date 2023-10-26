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

Using a file named **venv** in your projects root folder, it will automatically set the
virtual-env for such environment.

#### Dependency

This requires you to have the [project_nvim](https://github.com/ahmedkhalf/project.nvim)
package installed.

```lua
require('swenv.api').auto_venv()
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
