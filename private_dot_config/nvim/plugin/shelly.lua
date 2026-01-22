local M = {}

-- Store the marked terminal info
local marked_terminal = {
    buf = nil,
    job_id = nil,
    config = nil,
}

local defaults = {
    file = nil, -- file to open
    cmd = vim.o.shell, -- terminal command to run
    cwd = vim.fn.getcwd, -- cwd of the command
    id = function()
        return vim.v.count
    end, -- split identifier
    start_in_insert = true,
    focus = true,
    on_open = nil, -- callback(term, buf) when buffer is created
    on_exit = nil, -- callback(term, buf) when buffer is destroyed
    split = {
        direction = "horizontal", -- "horizontal" or "vertical"
        size = 12, -- size of the split (lines for horizontal, columns for vertical)
        position = "bottom", -- "top", "bottom", "left", "right"
    },
    wo = {
        cursorcolumn = false,
        cursorline = false,
        cursorlineopt = "both",
        fillchars = "eob: ,lastline:…",
        list = false,
        listchars = "extends:…,tab:  ",
        number = false,
        relativenumber = false,
        signcolumn = "no",
        spell = false,
        winbar = "",
        statuscolumn = "",
        wrap = false,
        sidescrolloff = 0,
    },
}

local config = defaults

M.set_config = function(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
end

M.get_config = function()
    return config
end

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

local function valid_buf(buf)
    return buf and vim.api.nvim_buf_is_valid(buf)
end
local function valid_win(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function get_split_cmd(config)
    local opts = eval_opts(config.split)
    local cmd = ""

    if opts.direction == "vertical" then
        if opts.position == "left" then
            cmd = "topleft vertical"
        else -- right
            cmd = "botright vertical"
        end
        cmd = cmd .. " " .. opts.size .. "split"
    else -- horizontal
        if opts.position == "top" then
            cmd = "topleft"
        else -- bottom
            cmd = "botright"
        end
        cmd = cmd .. " " .. opts.size .. "split"
    end

    return cmd
end

local function create_buf(config)
    local buf = nil
    if config.file then
        buf = vim.fn.bufadd(eval_opts(config.file))
        vim.fn.bufload(buf)
    else
        buf = vim.api.nvim_create_buf(false, true)
    end
    return buf
end

local function create_win(config, buf)
    local split_cmd = get_split_cmd(config)
    vim.cmd(split_cmd)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    for opt, val in pairs(config.wo) do
        vim.wo[win][opt] = val
    end
    return win
end

-- Function to check if the terminal is running IPython
local function is_ipython(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return false
    end

    -- Get the terminal buffer content to check for IPython prompt
    local lines = vim.api.nvim_buf_get_lines(buf, -10, -1, false)
    for _, line in ipairs(lines) do
        if string.match(line, "In %[%d+%]:") or string.match(line, "IPython") then
            return true
        end
    end
    return false
end

-- Function to send text to the marked terminal
local function send_to_terminal(text, force_ipython_mode)
    if not marked_terminal.buf or not vim.api.nvim_buf_is_valid(marked_terminal.buf) then
        vim.notify("No marked terminal found. Toggle a terminal first.", vim.log.levels.WARN)
        return
    end

    if not marked_terminal.job_id then
        vim.notify("Terminal job ID not found.", vim.log.levels.ERROR)
        return
    end

    -- Expand % symbols to current file path
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file and current_file ~= "" then
        text = string.gsub(text, "%%", vim.fn.shellescape(current_file))
    end

    -- Auto-detect IPython mode or use forced mode
    local use_ipython_mode = force_ipython_mode or is_ipython(marked_terminal.buf)

    if use_ipython_mode then
        -- Use IPython's %cpaste mode for multi-line code
        vim.api.nvim_chan_send(marked_terminal.job_id, "%cpaste -q\n")
        -- Wait a moment for cpaste to be ready
        vim.defer_fn(function()
            vim.api.nvim_chan_send(marked_terminal.job_id, text .. "\n")
            vim.api.nvim_chan_send(marked_terminal.job_id, "\x04") -- Ctrl-D to end paste mode
        end, 50)
    else
        -- Send the text to the terminal normally
        vim.api.nvim_chan_send(marked_terminal.job_id, text .. "\n")
    end
end

-- Function to send current line to terminal
local function send_current_line(force_ipython_mode)
    local line = vim.api.nvim_get_current_line()
    send_to_terminal(line, force_ipython_mode)
end

-- Function to send visual selection to terminal
local function send_visual_selection(force_ipython_mode)
    -- Get the visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

    if #lines == 0 then
        return
    end

    -- If single line, handle column selection
    if #lines == 1 then
        local line = lines[1]
        local start_col = start_pos[3] - 1
        local end_col = end_pos[3]
        lines[1] = string.sub(line, start_col + 1, end_col)
    else
        -- Multi-line selection: trim first and last lines
        local first_line = lines[1]
        local last_line = lines[#lines]
        lines[1] = string.sub(first_line, start_pos[3])
        lines[#lines] = string.sub(last_line, 1, end_pos[3])
    end

    local text = table.concat(lines, "\n")
    send_to_terminal(text, force_ipython_mode)
end

-- Function to check if a line is a cell delimiter
local function is_cell_delimiter(line)
    -- Cell delimiter pattern: # %%, -- %%, In[n], or ```
    return string.match(line, "^%s*[#%-%-]%s+%%%%") or string.match(line, "^%s*In%[%d+%]") or string.match(line, "^```")
end

-- Function to send current cell to terminal
local function send_current_cell(force_ipython_mode)
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    local total_lines = vim.api.nvim_buf_line_count(0)
    local all_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    -- Find the start of the current cell
    local cell_start = 1
    for i = current_line, 1, -1 do
        if is_cell_delimiter(all_lines[i]) then
            cell_start = i + 1
            break
        end
    end

    -- Find the end of the current cell
    local cell_end = total_lines
    local next_cell_start = nil
    for i = current_line + 1, total_lines do
        if is_cell_delimiter(all_lines[i]) then
            cell_end = i - 1
            next_cell_start = i
            break
        end
    end

    -- Get the cell content
    local cell_lines = vim.api.nvim_buf_get_lines(0, cell_start - 1, cell_end, false)

    -- Remove empty lines at the beginning and end
    while #cell_lines > 0 and string.match(cell_lines[1], "^%s*$") do
        table.remove(cell_lines, 1)
    end
    while #cell_lines > 0 and string.match(cell_lines[#cell_lines], "^%s*$") do
        table.remove(cell_lines, #cell_lines)
    end

    if #cell_lines == 0 then
        vim.notify("No cell content found", vim.log.levels.WARN)
        return
    end

    local text = table.concat(cell_lines, "\n")
    send_to_terminal(text, force_ipython_mode)

    -- Jump to the next cell if it exists
    if next_cell_start then
        vim.api.nvim_win_set_cursor(0, { next_cell_start, 0 })
    end
end

local function toggle(config, opts)
    opts = opts or {}
    local id = opts.id or eval_opts(config.id)
    if type(id) ~= "string" and type(id) ~= "number" then
        return
    end

    -- 0 is a special id to toggle previous float
    if id == 0 then
        id = config.prev_id or 1
    end
    local term = config.terms[id] or {}

    -- cmd and cwd need to be evaluated before window is created
    local cmd = eval_opts(config.cmd) or vim.o.shell
    local cwd = eval_opts(config.cwd) or vim.fn.getcwd()

    local buf_ready = valid_buf(term.buf)
    if not buf_ready then
        term.buf = create_buf(config)
        if config.on_open then
            config.on_open(config, term.buf)
        end

        vim.api.nvim_buf_set_option(term.buf, "buflisted", false)
        vim.api.nvim_buf_set_name(term.buf, "Shelly")

        vim.api.nvim_create_autocmd("BufDelete", {
            buffer = term.buf,
            once = true,
            callback = function()
                if config.on_exit then
                    config.on_exit(config, term.buf)
                end
                -- Clear marked terminal if this buffer is being deleted
                if marked_terminal.buf == term.buf then
                    marked_terminal.buf = nil
                    marked_terminal.job_id = nil
                    marked_terminal.config = nil
                end
            end,
        })
    end

    if valid_win(term.win) then
        vim.api.nvim_win_close(term.win, true)
    else
        -- ensure unwanted float window is closed
        if id ~= config.prev_id then
            local prev_term = config.terms[config.prev_id] or {}
            if valid_win(prev_term.win) then
                vim.api.nvim_win_close(prev_term.win, true)
            end
        end
        -- create new window
        local prev_win = vim.api.nvim_get_current_win()
        term.win = create_win(config, term.buf)
        if not config.file then
            -- ensure terminal command is executed before first show
            if not buf_ready then
                local job_id = vim.fn.jobstart(cmd, { cwd = cwd, term = true })
                if job_id == 0 then
                    vim.notify("floatty.nvim: Invalid arguments for terminal command", vim.log.levels.ERROR)
                    return
                elseif job_id == -1 then
                    vim.notify("floatty.nvim: Terminal command not executable: " .. cmd, vim.log.levels.ERROR)
                    return
                end
                -- Mark this terminal for sending commands
                marked_terminal.buf = term.buf
                marked_terminal.job_id = job_id
                marked_terminal.config = config
            else
                -- For existing buffer, get the job_id from buffer variable
                marked_terminal.buf = term.buf
                marked_terminal.job_id = vim.b[term.buf].terminal_job_id
                marked_terminal.config = config
            end
            if not eval_opts(config.focus) and valid_win(prev_win) then
                vim.api.nvim_set_current_win(prev_win)
            elseif eval_opts(config.start_in_insert) then
                vim.cmd.startinsert()
            end
        end
    end

    config.prev_id = id
    config.terms[id] = term
end

M.toggle = function(opts)
    local config = M.get_config()
    toggle(config, opts)
end

local function setup(config)
    config.terms = {}
    config.prev_id = nil

    -- Note: VimResized autocmd removed as splits handle resizing automatically

    -- Create the SendToTerminal command
    vim.api.nvim_create_user_command("SendToTerminal", function(opts)
        local force_ipython = opts.bang
        send_to_terminal(opts.args, force_ipython)
    end, {
        nargs = "+",
        bang = true,
        desc = "Send arbitrary text to the marked terminal (auto-detects IPython, use ! to force IPython mode)",
    })

    -- Create the SendLine command
    vim.api.nvim_create_user_command("SendLine", function(opts)
        local force_ipython = opts.bang
        send_current_line(force_ipython)
    end, {
        bang = true,
        desc = "Send current line to the marked terminal (auto-detects IPython, use ! to force IPython mode)",
    })

    -- Create the SendSelection command
    vim.api.nvim_create_user_command("SendSelection", function(opts)
        local force_ipython = opts.bang
        send_visual_selection(force_ipython)
    end, {
        range = true,
        bang = true,
        desc = "Send visual selection to the marked terminal (auto-detects IPython, use ! to force IPython mode)",
    })

    -- Create the SendCell command
    vim.api.nvim_create_user_command("SendCell", function(opts)
        local force_ipython = opts.bang
        send_current_cell(force_ipython)
    end, {
        bang = true,
        desc = "Send current cell (between # %%, -- %%, In[n], or ``` markers) to the marked terminal",
    })

    -- Create the ToggleTerm command
    vim.api.nvim_create_user_command("ToggleTerm", function(opts) end, {
        desc = "Toggle the terminal",
    })

    -- Set up key mappings
    vim.keymap.set("v", "<C-c>", function()
        send_visual_selection()
    end, { desc = "Send selection to terminal", silent = true })

    vim.keymap.set("n", "<C-c><C-c>", function()
        send_current_cell()
    end, { desc = "Send current cell to terminal", silent = true })

    return config
end

M.setup = function(opts)
    M.set_config(opts)
    local config = M.get_config()
    return setup(config)
end

M.setup({
    split = {
        direction = "horizontal",
        size = 12,
        position = "bottom",
    },
})

vim.keymap.set("n", "<C-q>", function()
    M.toggle()
end)
vim.keymap.set("t", "<C-q>", function()
    M.toggle()
end)
