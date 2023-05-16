local M = require('lualine.component'):extend()

local default_opts = {
  icon = "",
  color = { fg = "#8fb55e" },
}

function M:init(options)
  options = vim.tbl_deep_extend("keep", options or {}, default_opts)
  M.super.init(self, options)
end

function M:update_status()
  local venv = require('swenv.api').get_current_venv()
  if venv then
    return venv.name
  else
    return ''
  end
end

return M
