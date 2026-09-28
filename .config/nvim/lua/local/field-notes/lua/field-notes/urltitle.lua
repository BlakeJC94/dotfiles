local M = {}

-- AIDEV-NOTE: Namespace scoped to this plugin so extmarks don't collide.
local ns = vim.api.nvim_create_namespace("field-notes.url-title")

local NAMED_ENTITIES = {
    ["&amp;"] = "&",
    ["&lt;"] = "<",
    ["&gt;"] = ">",
    ["&quot;"] = '"',
    ["&#39;"] = "'",
    ["&apos;"] = "'",
    ["&nbsp;"] = " ",
}

local function decode_entities(text)
    text = text:gsub("&#(%d+);", function(n)
        return vim.fn.nr2char(tonumber(n))
    end)
    text = text:gsub("&#x(%x+);", function(n)
        return vim.fn.nr2char(tonumber(n, 16))
    end)
    return (text:gsub("&%a+;", function(entity)
        return NAMED_ENTITIES[entity] or entity
    end))
end

local function extract_title(body)
    local title = body:match("<[Tt][Ii][Tt][Ll][Ee][^>]*>(.-)</[Tt][Ii][Tt][Ll][Ee]>")
    if not title then
        return nil
    end

    title = vim.trim(title:gsub("%s+", " "))
    if title == "" then
        return nil
    end

    return decode_entities(title)
end

-- AIDEV-NOTE: Find the byte range of `url` on `line` at/after the cursor so
-- repeated URLs resolve to the occurrence the cursor is actually on.
local function find_url_range(line, url, col)
    local init, fallback = 1, nil
    while true do
        local first, last = line:find(url, init, true)
        if not first then
            break
        end
        if first - 1 <= col and col <= last - 1 then
            return first - 1, last
        end
        fallback = fallback or { first - 1, last }
        init = last + 1
    end
    if fallback then
        return fallback[1], fallback[2]
    end
end

-- AIDEV-NOTE: Fetch via curl rather than a Lua HTTP client; async (via
-- vim.system) so the UI stays responsive on slow pages.
local function curl(url, callback)
    local argv = { "curl", "-sL", "--max-time", "15", "-A", "Mozilla/5.0", url }
    if vim.system then
        vim.system(argv, { text = true }, function(out)
            callback(out.code, out.stdout or "")
        end)
    else
        local stdout = vim.fn.system(argv)
        callback(vim.v.shell_error, stdout)
    end
end

-- AIDEV-NOTE: Replace the URL under the cursor with a markdown link whose text
-- is the fetched page <title>. The URL is tracked with an extmark so unrelated
-- edits above it don't invalidate the replacement.
function M.url_title()
    local url = vim.fn.expand("<cfile>"):gsub("[%.,;:!?%)%]}>\"']+$", "")
    if not url:match("^https?://") then
        vim.notify("gX: no URL under cursor", vim.log.levels.WARN)
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local start_col = find_url_range(vim.api.nvim_get_current_line(), url, cursor[2])
    if not start_col then
        vim.notify("gX: no URL under cursor", vim.log.levels.WARN)
        return
    end

    local mark = vim.api.nvim_buf_set_extmark(bufnr, ns, cursor[1] - 1, start_col, {})
    vim.notify("gX: fetching " .. url .. " ...")

    curl(url, function(code, body)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                return
            end
            if code ~= 0 then
                vim.notify("gX: curl failed for " .. url, vim.log.levels.ERROR)
                return
            end

            local title = extract_title(body)
            if not title then
                vim.notify("gX: no title found for " .. url, vim.log.levels.WARN)
                return
            end

            local pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark, {})
            if not pos or #pos == 0 then
                vim.notify("gX: URL moved, aborting", vim.log.levels.WARN)
                return
            end

            local row, col = pos[1], pos[2]
            local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
            if line:sub(col + 1, col + #url) ~= url then
                vim.notify("gX: URL changed, aborting", vim.log.levels.WARN)
                return
            end

            vim.api.nvim_buf_set_text(bufnr, row, col, row, col + #url, { ("[%s](%s)"):format(title, url) })
            vim.api.nvim_buf_del_extmark(bufnr, ns, mark)
            vim.notify("gX: " .. title)
        end)
    end)
end

return M
