M = {}

-- Convert a list of CSV lines into a formatted Markdown table.
local function csv_lines_to_markdown(lines)
    local rows = {}
    local col_widths = {}

    for _, line in ipairs(lines) do
        local row = {}
        for field in string.gmatch(line, "([^,]+)") do
            table.insert(row, vim.trim(field))
        end
        table.insert(rows, row)
        for j, cell in ipairs(row) do
            col_widths[j] = math.max(col_widths[j] or 0, #cell)
        end
    end

    local result = {}
    for i, row in ipairs(rows) do
        local row_str = "|"
        for j, cell in ipairs(row) do
            row_str = row_str .. " " .. cell .. string.rep(" ", col_widths[j] - #cell) .. " |"
        end
        table.insert(result, row_str)

        -- Header separator after the first row
        if i == 1 then
            local sep = "|"
            for _, width in ipairs(col_widths) do
                sep = sep .. " " .. string.rep("-", width) .. " |"
            end
            table.insert(result, 2, sep)
        end
    end

    return result
end

-- Convert a list of Markdown table lines into CSV.
local function markdown_lines_to_csv(lines)
    local csv_lines = {}
    for _, line in ipairs(lines) do
        -- Skip separator row (---)
        if not line:match("^|%s*-+") then
            line = line:gsub("^|", ""):gsub("|$", "")
            local cells = {}
            for cell in line:gmatch("([^|]+)") do
                table.insert(cells, vim.trim(cell))
            end
            table.insert(csv_lines, table.concat(cells, ","))
        end
    end
    return csv_lines
end

-- Heuristic: any line starting with '|' looks like a Markdown table.
local function looks_like_markdown_table(lines)
    for _, line in ipairs(lines) do
        if line:match("^|") then
            return true
        end
    end
    return false
end

-- Pick a conversion based on the contents of `lines`.
local function convert_lines(lines)
    if looks_like_markdown_table(lines) then
        return markdown_lines_to_csv(lines)
    end
    return csv_lines_to_markdown(lines)
end

local function set_lines(start_pos, end_pos, result)
    vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, result)
end

-- Visual-selection entry points (global, for :command parity).

-- Operator entry point: works on the `g@` motion range (`'[`/`']`).
function ToggleTableFormatOperator(type)
    if type ~= "line" and type ~= "char" then
        return
    end
    local s, e = vim.fn.getpos("'["), vim.fn.getpos("']")
    set_lines(s, e, convert_lines(vim.fn.getline(s[2], e[2])))
end

local set_command_table_csv_to_md = function()
    vim.api.nvim_create_user_command("TableCsvToMd", function()
        local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
        set_lines(s, e, csv_lines_to_markdown(vim.fn.getline(s[2], e[2])))
    end, { range = true, desc = "Convert selected CSV to Markdown table" })
end

local set_command_table_md_to_csv = function()
    vim.api.nvim_create_user_command("TableMdToCsv", function()
        local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
        set_lines(s, e, markdown_lines_to_csv(vim.fn.getline(s[2], e[2])))
    end, { range = true, desc = "Convert selected Markdown table to CSV" })
end

local set_command_table_toggle = function()
    vim.api.nvim_create_user_command("TableToggle", function()
        local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
        set_lines(s, e, convert_lines(vim.fn.getline(s[2], e[2])))
    end, { range = true, desc = "Toggle selected CSV <-> Markdown table" })
end

function M.setup()
    set_command_table_csv_to_md()
    set_command_table_md_to_csv()
    set_command_table_toggle()
end

return M
