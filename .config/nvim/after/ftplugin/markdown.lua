vim.opt_local.formatoptions:remove("tc")
vim.opt_local.wrap = true
vim.opt_local.breakindentopt = "list:-1"
vim.opt_local.conceallevel = 1
vim.opt_local.foldlevel = 1

vim.opt_local.tabstop = 3
vim.opt_local.softtabstop = 3
vim.opt_local.shiftwidth = 3

vim.keymap.set("i", "<CR>", function()
    local api = vim.api
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local bufnr = 0

    local cur_line = api.nvim_get_current_line()

    -- NOTE: col is 0-based
    if col ~= #cur_line then
        return "<CR>"
    end

    local function indent_of(line)
        return #(line:match("^%s*") or "")
    end

    local function is_list(line)
        return line:match("^%s*%d+%.%s+") or line:match("^%s*[-*+] %[[ xX]%]%s*") or line:match("^%s*[-*+]%s+")
    end

    local search_row = row
    local owner_line = nil
    local owner_indent = nil

    while search_row > 0 do
        local line = api.nvim_buf_get_lines(bufnr, search_row - 1, search_row, false)[1]

        if not line or line:match("^%s*$") then
            break
        end

        local indent = indent_of(line)

        if is_list(line) then
            owner_line = line
            owner_indent = indent
            break
        end

        search_row = search_row - 1
    end

    if not owner_line then
        return "<CR>"
    end

    local indent = owner_line:match("^%s*") or ""

    -- Numbered list
    local num = owner_line:match("(%d+)%.%s+")
    if num then
        return string.format("<CR><C-o>0<C-o>d$%s%d. ", indent, tonumber(num) + 1)
    end

    -- Checkbox
    local checkbox = owner_line:match("[-*+] %[[ xX]%]%s*")
    if checkbox then
        return "<CR><C-o>0<C-o>d$" .. indent .. checkbox
    end

    -- Bullet
    local bullet = owner_line:match("[-*+]%s+")
    if bullet then
        return "<CR><C-o>0<C-o>d$" .. indent .. bullet
    end

    return "<CR>"
end, { expr = true })

function CsvToMarkdown()
    -- Get visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    -- Split each line into CSV fields
    local table_rows = {}
    local col_widths = {}

    for i, line in ipairs(lines) do
        local row = {}
        for field in string.gmatch(line, "([^,]+)") do
            field = vim.trim(field)
            table.insert(row, field)
        end
        table.insert(table_rows, row)
        -- Track max width for each column
        for j, cell in ipairs(row) do
            col_widths[j] = math.max(col_widths[j] or 0, #cell)
        end
    end

    -- Build markdown table
    local result = {}

    for i, row in ipairs(table_rows) do
        local row_str = "|"
        for j, cell in ipairs(row) do
            local padding = string.rep(" ", col_widths[j] - #cell)
            row_str = row_str .. " " .. cell .. padding .. " |"
        end
        table.insert(result, row_str)

        -- Add header separator after first row
        if i == 1 then
            local sep = "|"
            for _, width in ipairs(col_widths) do
                sep = sep .. " " .. string.rep("-", width) .. " |"
            end
            table.insert(result, 2, sep)
        end
    end

    -- Replace visual selection with result
    vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, result)
end

function MarkdownToCsv()
    -- Get visual selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    local csv_lines = {}

    for i, line in ipairs(lines) do
        -- Skip separator row (---)
        if not line:match("^|%s*-+") then
            -- Remove leading/trailing |
            line = line:gsub("^|", ""):gsub("|$", "")
            -- Split by | and trim spaces
            local cells = {}
            for cell in line:gmatch("([^|]+)") do
                cell = vim.trim(cell)
                table.insert(cells, cell)
            end
            table.insert(csv_lines, table.concat(cells, ","))
        end
    end

    -- Replace visual selection with CSV
    vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, csv_lines)
end

vim.api.nvim_create_user_command("CsvToMarkdown", function()
    CsvToMarkdown()
end, { range = true, desc = "Convert selected CSV to Markdown table" })

vim.api.nvim_create_user_command("MarkdownToCsv", function()
    MarkdownToCsv()
end, { range = true, desc = "Convert selected Markdown table to CSV" })

-- Toggle between CSV and Markdown using existing functions
function ToggleTableFormat()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    -- Simple detection: if any line starts with '|' and contains '|', assume Markdown
    local is_markdown = false
    for _, line in ipairs(lines) do
        if line:match("^|") and line:match("|") then
            is_markdown = true
            break
        end
    end

    if is_markdown then
        MarkdownToCsv()
    else
        CsvToMarkdown()
    end
end

-- Command to toggle format in visual mode
vim.api.nvim_create_user_command("ToggleTableFormat", function()
    ToggleTableFormat()
end, { range = true, desc = "Toggle selected CSV <-> Markdown table" })

vim.keymap.set("v", "<C-t>", ":ToggleTableFormat<CR>")

vim.keymap.set("n", "<C-t>", function()
    vim.o.operatorfunc = "v:lua.ToggleTableFormatOperator"
    return "g@"
end, { expr = true })

function ToggleTableFormatOperator(type)
    local start_pos, end_pos

    if type == "line" then
        start_pos = vim.fn.getpos("'[")
        end_pos = vim.fn.getpos("']")
    elseif type == "char" then
        start_pos = vim.fn.getpos("'[")
        end_pos = vim.fn.getpos("']")
    else
        return
    end

    local lines = vim.fn.getline(start_pos[2], end_pos[2])

    -- Simple detection: if any line starts with '|' and contains '|', assume Markdown
    local is_markdown = false
    for _, line in ipairs(lines) do
        if line:match("^|") and line:match("|") then
            is_markdown = true
            break
        end
    end

    if is_markdown then
        -- Convert markdown to CSV
        local csv_lines = {}
        for i, line in ipairs(lines) do
            -- Skip separator row (---)
            if not line:match("^|%s*-+") then
                -- Remove leading/trailing |
                line = line:gsub("^|", ""):gsub("|$", "")
                -- Split by | and trim spaces
                local cells = {}
                for cell in line:gmatch("([^|]+)") do
                    cell = vim.trim(cell)
                    table.insert(cells, cell)
                end
                table.insert(csv_lines, table.concat(cells, ","))
            end
        end
        vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, csv_lines)
    else
        -- Convert CSV to markdown
        local table_rows = {}
        local col_widths = {}

        for i, line in ipairs(lines) do
            local row = {}
            for field in string.gmatch(line, "([^,]+)") do
                field = vim.trim(field)
                table.insert(row, field)
            end
            table.insert(table_rows, row)
            -- Track max width for each column
            for j, cell in ipairs(row) do
                col_widths[j] = math.max(col_widths[j] or 0, #cell)
            end
        end

        -- Build markdown table
        local result = {}
        for i, row in ipairs(table_rows) do
            local row_str = "|"
            for j, cell in ipairs(row) do
                local padding = string.rep(" ", col_widths[j] - #cell)
                row_str = row_str .. " " .. cell .. padding .. " |"
            end
            table.insert(result, row_str)

            -- Add header separator after first row
            if i == 1 then
                local sep = "|"
                for _, width in ipairs(col_widths) do
                    sep = sep .. " " .. string.rep("-", width) .. " |"
                end
                table.insert(result, 2, sep)
            end
        end

        vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, result)
    end
end

vim.keymap.set({ "i", "n" }, "<C-.>", function()
    local api = vim.api
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local shiftwidth = vim.bo.shiftwidth

    -- Perform the indent
    vim.cmd("normal! >>")

    -- Move cursor to maintain relative position
    api.nvim_win_set_cursor(0, { row, col + shiftwidth })
end)

vim.keymap.set({ "i", "n" }, "<C-,>", function()
    local api = vim.api
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local shiftwidth = vim.bo.shiftwidth

    -- Perform the unindent
    vim.cmd("normal! <<")

    -- Move cursor to maintain relative position, but don't go negative
    local new_col = math.max(0, col - shiftwidth)
    api.nvim_win_set_cursor(0, { row, new_col })
end)

vim.keymap.set({ "i", "n" }, "<C-;>", function()
    local api = vim.api
    local cur_line = api.nvim_get_current_line()
    local row, col = unpack(api.nvim_win_get_cursor(0))

    local unchecked = cur_line:match("^(%s*[-*+] )%[ %](.*)$")
    local checked = cur_line:match("^(%s*[-*+] )%[[xX]%](.*)$")

    local num_unchecked = cur_line:match("^(%s*%d+%. )%[ %](.*)$")
    local num_checked = cur_line:match("^(%s*%d+%. )%[[xX]%](.*)$")

    local new_line

    if unchecked then
        local prefix, suffix = cur_line:match("^(%s*[-*+] )%[ %](.*)$")
        new_line = prefix .. "[x]" .. suffix
    elseif checked then
        local prefix, suffix = cur_line:match("^(%s*[-*+] )%[[xX]%](.*)$")
        new_line = prefix .. "[ ]" .. suffix
    elseif num_unchecked then
        local prefix, suffix = cur_line:match("^(%s*%d+%. )%[ %](.*)$")
        new_line = prefix .. "[x]" .. suffix
    elseif num_checked then
        local prefix, suffix = cur_line:match("^(%s*%d+%. )%[[xX]%](.*)$")
        new_line = prefix .. "[ ]" .. suffix
    else
        local list_prefix = cur_line:match("^(%s*[-*+] )(.*)$") or cur_line:match("^(%s*%d+%. )(.*)$")
        if list_prefix then
            local prefix, content = cur_line:match("^(%s*[-*+]?%s*%d*%.?%s*)(.*)$")
            new_line = (cur_line:match("^(%s*[-*+] )") or cur_line:match("^(%s*%d+%. )")) .. "[ ] " .. (content or "")
        else
            local indent = cur_line:match("^(%s*)")
            local content = cur_line:match("^%s*(.*)$")
            new_line = indent .. "- [ ] " .. content
        end
    end

    api.nvim_set_current_line(new_line)
end)

-- Treesitter folds
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Bakcground for code
local ns = vim.api.nvim_create_namespace("md_code_fence_bg")

vim.api.nvim_set_hl(0, "MdCodeFenceBg", { bg = "#282828" })

local function apply(bufnr)
    local parser = vim.treesitter.get_parser(bufnr, "markdown")
    local tree = parser:parse()[1]
    local root = tree:root()

    local query = vim.treesitter.query.parse(
        "markdown",
        [[
    (fenced_code_block
      (info_string)?
      (code_fence_content) @content)
  ]]
    )

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    for _, node in query:iter_captures(root, bufnr, 0, -1) do
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
