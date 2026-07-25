-- md-edit.lua
-- Markdown editing helpers: list indentation + checkbox toggling.
--
-- Single-file plugin. Load it any of these ways and it self-registers:
--   * drop in plugin/        (auto-sourced at startup)
--   * require("md-edit")     (runs once via package.loaded)
--   * source / dofile it
--
-- Provides (global mappings):
--   <C-.>  indent current line, preserving cursor column
--   <C-,>  unindent current line, preserving cursor column
--   <C-;>  toggle [x]/[ ] checkbox on current line (or insert one)

local M = {}

-- Toggle/insert a `[x]`/`[ ]` checkbox on the given line.
M.toggle_checkbox = function(line)
    -- Bullet list with checkbox
    local prefix, suffix = line:match("^(%s*[-*+] )%[ %](.*)$")
    if prefix then
        return prefix .. "[x]" .. suffix
    end
    prefix, suffix = line:match("^(%s*[-*+] )%[[xX]%](.*)$")
    if prefix then
        return prefix .. "[ ]" .. suffix
    end

    -- Numbered list with checkbox
    prefix, suffix = line:match("^(%s*%d+%. )%[ %](.*)$")
    if prefix then
        return prefix .. "[x]" .. suffix
    end
    prefix, suffix = line:match("^(%s*%d+%. )%[[xX]%](.*)$")
    if prefix then
        return prefix .. "[ ]" .. suffix
    end

    -- List item without a checkbox: insert one after the marker
    local list_prefix = line:match("^(%s*[-*+] )") or line:match("^(%s*%d+%. )")
    if list_prefix then
        local _, content = line:match("^(%s*[-*+]?%s*%d*%.?%s*)(.*)$")
        return list_prefix .. "[ ] " .. (content or "")
    end

    -- Plain line: turn it into a new checkbox bullet
    local indent = line:match("^(%s*)")
    local content = line:match("^%s*(.*)$")
    return indent .. "- [ ] " .. content
end

M.next_item = function()
    local api = vim.api
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local bufnr = 0

    local cur_line = api.nvim_get_current_line()

    -- NOTE: col is 0-based
    if col ~= #cur_line then
        return "<CR>"
    end

    local function is_list(line)
        return line:match("^%s*%d+%.%s+") or line:match("^%s*[-*+] %[[ xX]%]%s*") or line:match("^%s*[-*+]%s+")
    end

    local search_row = row
    local owner_line = nil

    while search_row > 0 do
        local line = api.nvim_buf_get_lines(bufnr, search_row - 1, search_row, false)[1]

        if not line or line:match("^%s*$") then
            break
        end

        if is_list(line) then
            owner_line = line
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
end

return M
