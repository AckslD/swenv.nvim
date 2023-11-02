local M = {}

local Path = require('plenary.path')
local scan_dir = require('plenary.scandir').scan_dir

local settings = require('swenv.config').settings

local ORIGINAL_PATH = vim.fn.getenv('PATH')

local current_venv = nil

local update_path = function(path)
    vim.fn.setenv('PATH', path .. '/bin' .. ':' .. ORIGINAL_PATH)
end

local set_venv = function(venv)
    if venv.source == 'conda' then
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
local has_high_priority_in_path = function(first, second)
    if first == nil or first == vim.NIL then
        return false
    end

    if second == nil or second == vim.NIL then
        return true
    end

    return string.find(ORIGINAL_PATH, first) < string.find(ORIGINAL_PATH, second)
end


-- Function for computing the Levenshtein distance (fuzzy search)
local function lev(str1, str2)
    local len1, len2 = #str1, #str2
    local matrix = {}
    for i = 0, len1 do matrix[i] = { [0] = i } end
    for j = 0, len2 do matrix[0][j] = j end
    for i = 1, len1 do
        for j = 1, len2 do
            local cost = str1:byte(i) == str2:byte(j) and 0 or 1
            matrix[i][j] = math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
        end
    end
    return matrix[len1][len2]
end

-- Function to find the best match based on Levenshtein distance
local function best_match(items, query)
    local min_distance = math.huge             -- Initialize minimum distance as infinity
    local match = nil                          -- Initialize match as nil to handle case if no match found
    for _, item in ipairs(items) do            -- Iterate over items
        local distance = lev(query, item.name) -- Compute Levenshtein distance to the query
        if distance < min_distance then        -- If this item is closer to query...
            min_distance = distance            -- Update minimum distance
            match = item                       -- Update the match
        end
    end
    return match -- Return the best match
end

-- Get the name from a `.venv` file in the project root directory.
local function read_venv_name(project_dir)
    local file = io.open(project_dir .. '/.venv', "r") -- r read mode
    if not file then return nil end
    local content = file:read "*a"                     -- *a or *all reads the whole file
    file:close()
    return content:match "^%s*(.-)%s*$"                -- Trim whitespace
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

local get_venvs_for = function(base_path, source, opts)
  local venvs = {}
  if base_path == nil then
    return venvs
  end
  local paths = scan_dir(
    base_path,
    vim.tbl_extend(
      'force',
      { depth = 1, only_dirs = true, silent = true },
      opts or {}
    )
  )
  for _, path in ipairs(paths) do
      table.insert(venvs, {
        name = Path:new(path):make_relative(base_path),
        path = path,
        source = source,
      })
  end
  return venvs
end

local get_conda_base_path = function()
  local conda_exe = vim.fn.getenv('CONDA_EXE')
  if conda_exe == vim.NIL then
    return nil
  else
    return Path:new(conda_exe):parent():parent() .. '/envs'
  end
end

local get_pyenv_base_path = function()
  local pyenv_root = vim.fn.getenv('PYENV_ROOT')
  if pyenv_root == vim.NIL then
    return nil
  else
    return Path:new(pyenv_root) .. "/versions"
  end
end

M.get_venvs = function(venvs_path)
  local venvs = {}
  vim.list_extend(venvs, get_venvs_for(venvs_path, 'venv'))
  vim.list_extend(venvs, get_venvs_for(get_conda_base_path(), 'conda'))
  vim.list_extend(venvs, get_venvs_for(get_pyenv_base_path(), 'pyenv'))
  vim.list_extend(venvs, get_venvs_for(get_pyenv_base_path(), 'pyenv', {only_dirs = false}))
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

M.set_venv = function(name)
    local venvs = settings.get_venvs(settings.venvs_path)
    local closest_match = best_match(venvs, name)
    if not closest_match then
        return
    end
    set_venv(closest_match)
end

M.auto_venv = function()
    local loaded, project_nvim = pcall(require, "project_nvim.project")
    local venvs = settings.get_venvs(settings.venvs_path)
    local project_dir = nil
    if loaded then
        project_dir, _ = project_nvim.get_project_root()
    else
        print("Error: failed to load the project_nvim.project module")
        return
    end
    if project_dir then
        local project_venv_name = read_venv_name(project_dir)
        if not project_venv_name then return end
        local closest_match = best_match(venvs, project_venv_name)
        if not closest_match then return end
        set_venv(closest_match)
    end
end

return M
