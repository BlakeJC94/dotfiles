M = {}

local function is_backtick_fence(line)
    return line:match("^%s*```") ~= nil or line:match("^%s*~~~") ~= nil
end

local function surrounding_fence_pair()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local fences = {}

    for i, line in ipairs(lines) do
        if is_backtick_fence(line) then
            table.insert(fences, i)
        end
    end

    for i = 1, #fences - 1, 2 do
        local open_row = fences[i]
        local close_row = fences[i + 1]
        if row >= open_row and row <= close_row then
            return open_row, close_row
        end
    end

    return nil, nil
end

M.select_fenced_code = function(inner)
    local open_row, close_row = surrounding_fence_pair()
    if not open_row or not close_row then
        return
    end

    local start_row = inner and (open_row + 1) or open_row
    local end_row = inner and (close_row - 1) or close_row

    -- AIDEV-NOTE: `ic` intentionally no-ops for empty fenced blocks (adjacent fences).
    if start_row > end_row then
        return
    end

    local mode = vim.fn.mode(1)
    if mode:sub(1, 1) == "v" or mode == "V" or mode == "\22" then
        vim.cmd("normal! \27")
    end

    vim.api.nvim_win_set_cursor(0, { start_row, 0 })
    vim.cmd("normal! V")
    vim.api.nvim_win_set_cursor(0, { end_row, 0 })
end

M.setup = function(opts)
    vim.api.nvim_set_hl(0, "MdCodeFenceBg", { bg = opts.bg })

    local ns = vim.api.nvim_create_namespace("md_code_fence_bg")

    local fence_query

    local function apply(bufnr)
        local parser = vim.treesitter.get_parser(bufnr, "markdown")
        local tree = parser:parse()[1]
        local root = tree:root()

        if not fence_query then
            fence_query = vim.treesitter.query.parse(
                "markdown",
                [[
                    (fenced_code_block
                      (info_string)?
                      (code_fence_content) @content)
                ]]
            )
        end

        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        for _, node in fence_query:iter_captures(root, bufnr, 0, -1) do
            local sr, _, er, _ = node:range()
            vim.api.nvim_buf_set_extmark(bufnr, ns, sr, 0, {
                end_line = er,
                hl_group = "MdCodeFenceBg",
                hl_eol = true,
                priority = 100,
            })
        end
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
        pattern = "*.md",
        callback = function(args)
            pcall(apply, args.buf)
        end,
    })
end

return M
