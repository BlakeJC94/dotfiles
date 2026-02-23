local M = {}

-- Store the marked buffer info
local marked_info = { buf = nil, job_id = nil, win = nil }

local CONFIG = {
    split = {
        direction = "horizontal",
        size = 16,
        position = "bottom",
    },
    wo = {
        cursorcolumn = false,
        cursorline = false,
        number = false,
        relativenumber = false,
        signcolumn = "no",
        spell = false,
        wrap = false,
    },
}

local function eval_opts(opts)
    if type(opts) == "function" then
        return opts()
    end
    if type(opts) == "table" then
        local res = {}
        for k, v in pairs(opts) do
            res[k] = eval_opts(v)
        end
        return res
    end
    return opts
end

local function get_split_cmd(config)
    local opts = eval_opts(config.split)
    local pos = (opts.position == "left" or opts.position == "top") and "topleft" or "botright"
    local dir = opts.direction == "vertical" and " vertical" or ""
    return pos .. dir .. " " .. opts.size .. "split"
end

local function create_win(config, buf)
    vim.cmd(get_split_cmd(config))
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    for opt, val in pairs(config.wo) do
        vim.wo[win][opt] = val
    end
    return win
end

M.toggle = function()
    local info = marked_info
    local buf_ready = info.buf and vim.api.nvim_buf_is_valid(info.buf)

    -- Create buffer if needed
    if not buf_ready then
        info.buf = vim.api.nvim_create_buf(false, true)
        vim.bo[info.buf].buflisted = false
        vim.api.nvim_buf_set_name(info.buf, "LLM")

        vim.api.nvim_create_autocmd("BufDelete", {
            buffer = info.buf,
            once = true,
            callback = function()
                marked_info.buf = nil
                marked_info.job_id = nil
                marked_info.win = nil
            end,
        })
    end

    -- Toggle window
    if info.win and vim.api.nvim_win_is_valid(info.win) then
        vim.api.nvim_win_close(info.win, true)
        info.win = nil
    else
        local prev_win = vim.api.nvim_get_current_win()
        info.win = create_win(CONFIG, info.buf)

        if vim.api.nvim_win_is_valid(prev_win) then
            vim.api.nvim_set_current_win(prev_win)
        end
    end
end

M.llm = function(cmd_opts)
    local bang = cmd_opts.bang
    print(bang)

    local args = cmd_opts.args
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file ~= "" then
        args = args:gsub("()%%%S*", function(pos)
            if pos > 1 and args:sub(pos - 1, pos - 1) == "\\" then
                return nil
            end
            return vim.fn.expand(args:sub(pos))
        end)
    end

    local cmd_to_exec = "llm" .. " " .. args

    -- Check if we are in visual mode and get the selection range
    local text = nil
    if cmd_opts.range > 0 then
        print("TRACE")
        -- Exit visual mode to update '< and '> marks, then get the selection
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
        local start_pos = math.min(cmd_opts.line1, cmd_opts.line2)
        local end_pos = math.max(cmd_opts.line1, cmd_opts.line2)
        local lines = vim.api.nvim_buf_get_lines(0, start_pos - 1, end_pos, false)

        if #lines >= 1 then
            text = table.concat(lines, "\n")
        end
    end

    if bang then
        -- synchronous exec, write output to cursor
        -- TODO Display a spinner on the command prompt while this works
        local output, err
        if text then
            output, err = vim.fn.system({ "sh", "-c", cmd_to_exec }, text)
        else
            output, err = vim.fn.system({ "sh", "-c", cmd_to_exec })
        end

        if err then
            vim.notify("llm failed: " .. err, vim.log.levels.ERROR)
            return
        end

        local lnum = vim.fn.line(".")
        local output_lines = vim.fn.split("\n" .. output, "\n")
        -- TODO: Is it possible to add comment headers to this?
        vim.fn.append(lnum, output_lines)
    else
        -- Asynchronous output
        print("TODO")
    end
end

M.setup = function(opts)
    CONFIG = vim.tbl_deep_extend("force", CONFIG, opts or {})

    local commands = {
        {
            name = "LLM",
            fn = M.llm,
            opts = { range = true, bang = true, nargs = "+", desc = "Invoke LLM Command" },
        },
        {
            name = "LLMToggle",
            fn = M.toggle,
            opts = { desc = "Toggle LLM Buffer" },
        },
    }

    for _, cmd in ipairs(commands) do
        vim.api.nvim_create_user_command(cmd.name, cmd.fn, cmd.opts)
    end
end

return M
