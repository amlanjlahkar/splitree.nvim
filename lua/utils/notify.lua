local M = {}

---Clear command-line before printing message
---@param msg string Message to pass into vim.notify
---@param level? integer|nil One of the values from vim.log.levels
function M.notify(msg, level)
    level = level or vim.log.levels.OFF
    vim.api.nvim_feedkeys(":", "nx", true)
    vim.notify(msg, level)
end

return M
