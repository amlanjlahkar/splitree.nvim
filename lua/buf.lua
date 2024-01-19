local api = vim.api
local fn = vim.fn
local uv = vim.loop

local markname = "f"

local M = {}

---Load the filetree buffer
---@param bufnr integer
---@param mark table Tuple(row, col) representing location of filepath in `bufnr`
M.load_buf = function(bufnr, mark)
    local ns_id = api.nvim_create_namespace("splitree.hl_fname")

    api.nvim_buf_add_highlight(bufnr, ns_id, "PmenuSel", mark[1] - 1, mark[2], -1)
    api.nvim_buf_set_option(bufnr, "ma", false)
    vim.cmd("vsp | buf " .. bufnr)
    api.nvim_win_set_option(0, "stc", "")
    api.nvim_win_set_option(0, "nu", false)
    api.nvim_win_set_option(0, "rnu", false)
    api.nvim_win_set_cursor(0, mark)
    vim.cmd("wincmd p")
end

---View the filetree buffer
---@param bufnr integer
M.view_buf = function(bufnr)
    local mark = api.nvim_buf_get_mark(bufnr, markname)

    if mark[1] > 0 and mark[2] > 0 then
        M.load_buf(bufnr, mark)
    else
        require("utils.notify").notify("Loading filetree...", vim.log.levels.INFO)
        vim.defer_fn(function()
            M.load_buf(bufnr, api.nvim_buf_get_mark(bufnr, markname))
        end, 5000)
    end
end

---Create the filetree buffer.
---@param args table List of arguments to pass to `tree`
---@param url string Custom url to use as buffer name
---@param fpath string Absolute filepath of current file
M.create_buf = vim.schedule_wrap(function(args, url, fpath)
    local def_args = {
        "-anlF",
        "--dirsfirst",
        "--gitignore",
        "-I",
        ".git",
    }

    args = args and vim.tbl_flatten({ args, "--dirsfirst" }) or def_args

    local bufnr = require("utils.jobwrite").jobstart("tree", args, uv.cwd())

    if bufnr then
        vim.schedule(function()
            local rel_fpath = fn.fnamemodify(fn.resolve(fpath), ":.")

            local fpath_comps = {}

            local is_fullpath = vim.tbl_contains(args, "-f")

            if is_fullpath then
                fpath_comps = { "./" .. rel_fpath }
            else
                fpath_comps = vim.split(fn.fnamemodify(fn.resolve(fpath), ":."), "/", { plain = true })
            end

            local idx = 1

            api.nvim_buf_attach(bufnr, false, {
                on_lines = function(_, _, _, _, cfline)
                    local line = api.nvim_buf_get_lines(bufnr, cfline, cfline + 1, false)[1]

                    local cfname_idx = (line:find("[%w%.%_]"))

                    local cfname = line:sub(cfname_idx)

                    local set_mark = function()
                        api.nvim_buf_set_mark(bufnr, markname, cfline + 1, cfname_idx - 1, {})
                        return true
                    end

                    local is_valid = (cfname:find(string.format("^%s[/=|%%*]?$", fpath_comps[idx])))

                    if cfname == fpath_comps[idx] or is_valid then
                        if idx == #fpath_comps then
                            if is_fullpath then
                                set_mark()
                            end

                            local depth = cfname_idx and math.floor(((cfname_idx - 1) / 5) - 1) or -1

                            if depth ~= #fpath_comps then
                                idx = 0
                            else
                                set_mark()
                            end
                        end

                        idx = idx + 1
                    end
                end,
            })
        end)

        api.nvim_buf_set_name(bufnr, url)
        api.nvim_buf_set_option(bufnr, "ft", "filetree")

        vim.defer_fn(function()
            M.view_buf(bufnr)
        end, 300)
    end
end)

return M
