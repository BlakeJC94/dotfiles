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
    local start_pos = vim.api.nvim_buf_get_mark(0, "<")
    local end_pos = vim.api.nvim_buf_get_mark(0, ">")
    M._reverse_lines(0, start_pos[1], end_pos[1])
end

-- Setup reverse motion with keymaps
M.setup_reverse = function()
    -- Operator pending: gR{motion}
    vim.keymap.set("n", "gR", function()
        vim.go.operatorfunc = "v:lua.BlakeJC94.reverse_op"
        return "g@"
    end, { expr = true, silent = true, desc = "Reverse lines operator" })

    -- Visual mode: gR
    vim.keymap.set("x", "gR", function()
        -- Exit visual mode to ensure marks are finalized (though they should be set)
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "x", false)

        M.reverse_vis()
    end, { silent = true, desc = "Reverse selected lines" })
end

-- Sort lines operator
M.sort_lines = function(type)
    local marks
    if type == "vis" then
        marks = { "<", ">" }
    else
        marks = { "[", "]" }
    end

    local _, l1, _, _ = unpack(vim.fn.getpos("'" .. marks[1]))
    local _, l2, _, _ = unpack(vim.fn.getpos("'" .. marks[2]))

    vim.cmd(l1 .. "," .. l2 .. "sort")
end

-- Setup sort motion with keymaps
M.setup_sort = function()
    -- Normal mode: operator pending (gs{motion})
    vim.keymap.set("n", "gs", function()
        vim.go.operatorfunc = "v:lua.BlakeJC94.sort_lines"
        return "g@"
    end, { expr = true, silent = true, desc = "Sort lines (operator)" })

    -- Visual mode: sort selection
    vim.keymap.set("v", "gs", function()
        M.sort_lines("vis")
    end, { silent = true, desc = "Sort selected lines" })
end

return M
