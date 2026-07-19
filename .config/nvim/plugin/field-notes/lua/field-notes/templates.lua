local config = require("field-notes.config")
local M = {}

local function resolve_base_timestamp(base, context)
    local now = (context and context.reference_timestamp) or os.time()
    if base == "today" then
        return now
    elseif base == "monday" then
        local weekday = tonumber(os.date("%u", now))
        return now - ((weekday - 1) * 86400)
    end
    return now
end

local function format_strftime(fmt, base, offset, context)
    local ts = resolve_base_timestamp(base, context)
    ts = ts + (offset * 86400)
    return os.date(fmt, ts)
end

function M.template_dir()
    return config.get("field_notes_templates_dir") or (config.get("field_notes_dir") .. "/_templates")
end

function M.list_templates()
    local dir = M.template_dir()
    local items = {}

    local handle = vim.uv.fs_scandir(dir)
    if not handle then
        return items
    end

    while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then
            break
        end
        if type == "file" and name:match("%.md$") then
            local stem = name:gsub("%.md$", "")
            table.insert(items, stem)
        end
    end

    table.sort(items)
    return items
end

function M.apply_template(template_name, title, context)
    local dir = M.template_dir()
    local path = dir .. "/" .. template_name .. ".md"

    local fd = vim.uv.fs_open(path, "r", 438)
    if not fd then
        return nil
    end

    local stat = vim.uv.fs_fstat(fd)
    local data = vim.uv.fs_read(fd, stat.size, 0)
    vim.uv.fs_close(fd)

    local content = data
    -- AIDEV-NOTE: {{week}} uses Monday-based %W numbering and Monday date for stable weekly templates.
    local week_monday = resolve_base_timestamp("monday", context)
    local week_title = os.date("%Y-W%W: %b %d", week_monday)

    content = content:gsub("{{title}}", title)
    content = content:gsub("{{date}}", os.date("%Y-%m-%d"))
    content = content:gsub("{{week}}", week_title)
    content = content:gsub("{{strftime:([^}:]+):([^}]+)}}", function(fmt, expr)
        local base, offset_str = expr:match("^(%a+)([+-]?%d+)$")
        if base then
            return format_strftime(fmt, base, tonumber(offset_str), context)
        end
        return "{{strftime:" .. fmt .. ":" .. expr .. "}}"
    end)
    content = content:gsub("{{strftime:([^}]+)}}", function(fmt)
        return os.date(fmt)
    end)

    return vim.split(content, "\n", { plain = true })
end

return M
