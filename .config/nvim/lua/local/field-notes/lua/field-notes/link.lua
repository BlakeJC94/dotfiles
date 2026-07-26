local config = require("field-notes.config")
local utils = require("field-notes.utils")

local M = {}

function M.link_note(title, source_path)
    local filename = utils.slugify(title) .. ".md"
    local note_path = config.get("field_notes_dir") .. "/" .. filename
    local filepath = "./" .. filename

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
