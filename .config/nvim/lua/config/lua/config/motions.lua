local M = {}

-- Core function to reverse lines in a range (1-indexed, inclusive)
M._reverse_lines = function(bufnr, l1, l2)
    if l1 == l2 then
        return
    end

    -- Handle backwards selection (ensure l1 <= l2)
    if l1 > l2 then
        l1, l2 = l2, l1
    end

    -- Get lines (0-indexed for API)
    local lines = vim.api.nvim_buf_get_lines(bufnr, l1 - 1, l2, false)

    -- Reverse in-place using two-pointer swap
    for i = 1, math.floor(#lines / 2) do
        local j = #lines - i + 1
        lines[i], lines[j] = lines[j], lines[i]
    end

    vim.api.nvim_buf_set_lines(bufnr, l1 - 1, l2, false, lines)
end

-- Operatorfunc callback (used with g@)
M.reverse_op = function(type)
    -- type is 'line', 'char', or 'block' - we treat all as line-wise
    local start_pos = vim.api.nvim_buf_get_mark(0, "[")
    local end_pos = vim.api.nvim_buf_get_mark(0, "]")
    M._reverse_lines(0, start_pos[1], end_pos[1])
end

-- Visual mode handler
M.reverse_vis = function()
    -- Use the live selection start ("v") and the cursor; '< / '> marks are
    -- only finalized after leaving visual mode
    local l1 = vim.fn.getpos("v")[2]
    local l2 = vim.fn.line(".")
    M._reverse_lines(0, l1, l2)
end

-- Setup reverse motion with keymaps
M.setup_reverse = function()
    -- Operator pending: gR{motion}
    vim.keymap.set("n", "gR", function()
        vim.go.operatorfunc = "v:lua.config.reverse_op"
        return "g@"
    end, { expr = true, silent = true, desc = "Reverse lines operator" })

    -- Visual mode: gR
    -- Stays in visual mode; the buffer API doesn't move the cursor, so the
    -- selection keeps covering the same range of lines after reversing
    vim.keymap.set("x", "gR", function()
        M.reverse_vis()
    end, { silent = true, desc = "Reverse selected lines" })
end

-- Sort lines operator
M.sort_lines = function(type)
    local l1, l2
    if type == "vis" then
        -- Called from the visual-mode mapping, which stays in visual mode:
        -- use the live selection start ("v") and the cursor position
        l1 = vim.fn.getpos("v")[2]
        l2 = vim.fn.line(".")
    else
        l1 = vim.fn.getpos("'[")[2]
        l2 = vim.fn.getpos("']")[2]
    end

    -- Handle backwards selection (ensure l1 <= l2)
    if l1 > l2 then
        l1, l2 = l2, l1
    end

    if type == "vis" then
        -- Replace lines through the API: unlike :sort, this doesn't move the
        -- cursor, so the visual selection stays on the same range of lines
        local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
        table.sort(lines)
        vim.api.nvim_buf_set_lines(0, l1 - 1, l2, false, lines)
    else
        vim.cmd(l1 .. "," .. l2 .. "sort")
    end
end

-- Setup sort motion with keymaps
M.setup_sort = function()
    -- Normal mode: operator pending (gs{motion})
    vim.keymap.set("n", "gs", function()
        vim.go.operatorfunc = "v:lua.config.sort_lines"
        return "g@"
    end, { expr = true, silent = true, desc = "Sort lines (operator)" })

    -- Visual mode: sort selection
    -- Stays in visual mode; sort_lines uses the buffer API (no cursor
    -- movement), so the selection keeps covering the same range of lines
    vim.keymap.set("v", "gs", function()
        M.sort_lines("vis")
    end, { silent = true, desc = "Sort selected lines" })
end

return M
