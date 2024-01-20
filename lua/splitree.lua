local fn = vim.fn
local api = vim.api
local uv = vim.loop

local buf = require("buf")
local notify = require("utils.notify").notify

local M = {}

M.splitree = function(args)
    local fpath = fn.expand("%:p")
    local f = uv.fs_stat(fpath)

    if not f or f.type ~= "file" then
        notify("Not a valid file", vim.log.levels.ERROR)
        return
    end

    local ft = "splitree"
    local url = "sptree://" .. fpath

    require("utils.display"):init(url, buf.view_buf, function()
        buf.create_buf(args, fpath, ft, url)
    end)
end

M.register_usrcmd = function(args)
    args = args or {}
    local name = "Splitree"

    if fn.exists(":" .. name) == 2 then
        notify("[Splitree.nvim]: User command with same name already exists! Aborting...", vim.log.levels.WARN)
        return
    end

    api.nvim_create_user_command(name, function()
        M.splitree(args)
    end, {
        nargs = 0,
        bar = true,
        bang = false,
        desc = "Hierarchically display files under cwd relative to current file",
    })
end

M.setup = function(opt)
    if opt and opt.args then
        assert(type(opt.args) == "table", "Arguments must be passed inside a table!")
        M.register_usrcmd(opt.args)
    else
        M.register_usrcmd()
    end
end

return M
