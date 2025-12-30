vim.opt_local.formatoptions:remove("tc")
vim.opt_local.wrap = true
vim.opt_local.breakindentopt = "list:-1"
-- vim.opt_local.conceallevel = 1
vim.opt_local.foldlevel = 1

vim.opt_local.tabstop = 2
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2

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
