local api = vim.api
local fn = vim.fn
local uv = vim.loop
local notify = require("utils.notify").notify

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
    local winid = api.nvim_get_current_win()
    api.nvim_win_set_option(winid, "stc", "")
    api.nvim_win_set_option(winid, "nu", false)
    api.nvim_win_set_option(winid, "rnu", false)
    api.nvim_win_set_cursor(winid, mark)
    vim.cmd("wincmd p")
end

---View the filetree buffer
---@param bufnr integer
M.view_buf = function(bufnr)
    local mark = api.nvim_buf_get_mark(bufnr, markname)

    if mark[1] > 0 and mark[2] > 0 then
        M.load_buf(bufnr, mark)
    else
        notify("Loading filetree...", vim.log.levels.INFO)
        vim.defer_fn(function()
            M.load_buf(bufnr, api.nvim_buf_get_mark(bufnr, markname))
        end, 5000)
    end
end

---Create the filetree buffer.
---@param args table List of arguments to pass to `tree`
---@param fpath string Absolute filepath of current file
---@param ft string Filetype to set for buffer
---@param url string Url to use as buffer name
M.create_buf = vim.schedule_wrap(function(args, fpath, ft, url)
    local def_args = {
        "-a", -- list all files
        "-l", -- follow symlinks
        "-n", -- turn off colorization
        "-F", -- append file type indicator
        "--dirsfirst", -- list directories first(!IMPORTANT!)
        "--gitignore", -- ignore git files
        "-I",
        ".git", -- ignore .git directory
    }

    args = vim.tbl_isempty(args) and def_args or vim.tbl_flatten({ args, "-n", "--dirsfirst" })

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

            local set_mark = function(line, col)
                api.nvim_buf_set_mark(bufnr, markname, line, col, {})
                return true
            end

            local idx = 1

            api.nvim_buf_attach(bufnr, false, {
                on_lines = function(_, _, _, _, lastline, lastline_up)
                    local line = api.nvim_buf_get_lines(bufnr, lastline, lastline_up, true)[1]

                    local fname_col = (line:find("[%w%.%_]"))

                    local fname = line:sub(fname_col)

                    local matched_col = (fname:find(string.format("^%s[/=|%%*]?$", fpath_comps[idx])))

                    if fname == fpath_comps[idx] or matched_col then
                        if idx == #fpath_comps then
                            if is_fullpath then
                                set_mark(lastline_up, fname_col - 1)
                            end

                            local depth = fname_col and math.floor(((fname_col - 1) / 5) - 1) or -1

                            if depth ~= #fpath_comps then
                                idx = 0
                            else
                                set_mark(lastline_up, fname_col - 1)
                            end
                        end

                        idx = idx + 1
                    end
                end,
            })
        end)

        api.nvim_buf_set_option(bufnr, "ft", ft)
        api.nvim_buf_set_name(bufnr, url)

        vim.defer_fn(function()
            M.view_buf(bufnr)
        end, 300)
    end
end)

return M
