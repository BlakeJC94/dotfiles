local config = require("field-notes.config")
local utils = require("field-notes.utils")

local M = {}
local last_note_path

local function insert_link(title, note_path, source_path, absolute_fallback)
    local filename = vim.fn.fnamemodify(note_path, ":t")
    local filepath = absolute_fallback and note_path or "./" .. filename

    local resolved_source_path = source_path

    -- AIDEV-NOTE: Use source path to build relative links; fallback is alternate file path (#:p).
    if not resolved_source_path or resolved_source_path == "" then
        resolved_source_path = vim.fn.expand("#:p")
    end
    if resolved_source_path ~= "" then
        local source_dir = vim.fn.fnamemodify(resolved_source_path, ":p:h")
        local relpath = vim.fs.relpath(source_dir, note_path)
        if relpath and relpath ~= "" then
            filepath = relpath
        end
    end

    local markdown_text = "[" .. title .. "](" .. filepath .. ")"

    if vim.fn.expand("%:e") == "md" then
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local line = vim.api.nvim_get_current_line()
        local before = line:sub(1, col)
        local after = line:sub(col + 1)
        vim.api.nvim_set_current_line(before .. markdown_text .. after)
        vim.api.nvim_win_set_cursor(0, { row, col + #markdown_text })
    end
end

function M.link_note(title, source_path)
    local filename = utils.slugify(title) .. ".md"
    insert_link(title, config.get("field_notes_dir") .. "/" .. filename, source_path)
end

function M.link_last_note()
    if not last_note_path then
        print("Error: no previously viewed field note")
        return
    end
    if vim.fn.filereadable(last_note_path) ~= 1 then
        print("Error: field note is not readable: " .. last_note_path)
        return
    end

    local title
    for _, line in ipairs(vim.fn.readfile(last_note_path)) do
        title = line:match("^#%s+(.+)")
        if title then
            break
        end
    end
    if not title then
        print("Error: field note has no # heading: " .. last_note_path)
        return
    end

    insert_link(title, last_note_path, vim.fn.expand("%:p"), true)
end

function M.setup()
    local group = vim.api.nvim_create_augroup("field-notes.link", { clear = true })
    vim.api.nvim_create_autocmd("BufLeave", {
        group = group,
        callback = function(event)
            local path = vim.api.nvim_buf_get_name(event.buf)
            local notes_dir = vim.fs.normalize(vim.fn.fnamemodify(config.get("field_notes_dir"), ":p"))
            if path:match("%.md$") and vim.fs.dirname(vim.fs.normalize(path)) == notes_dir then
                last_note_path = path
            end
        end,
    })
end

-- AIDEV-NOTE: :NoteLink supports optional [path] before quoted title; defaults to alternate file (#).
M.parse_note_link_args = function(args)
    local trimmed = vim.trim(args or "")
    if trimmed == "" then
        return nil, nil, "Error: :NoteLink expects a title"
    end

    local source_path, title = trimmed:match('^(.-)%s*"([^"]+)"%s*$')
    if not title then
        source_path, title = trimmed:match("^(.-)%s*'([^']+)'%s*$")
    end

    if title then
        source_path = vim.trim(source_path or "")
        if source_path == "" then
            source_path = vim.fn.expand("#")
        end
        return source_path, title, nil
    end

    return vim.fn.expand("#"), trimmed, nil
end

return M
