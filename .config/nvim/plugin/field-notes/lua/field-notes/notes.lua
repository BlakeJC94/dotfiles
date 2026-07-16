local config = require("field-notes.config")
local utils = require("field-notes.utils")
local templates = require("field-notes.templates")
local M = {}

-- AIDEV-NOTE: :Note accepts a quoted title and optional template name.
local function parse_quoted_note_arg(args)
    local trimmed = vim.trim(args or "")

    local quoted_title = trimmed:match('^"([^"]+)"')
    if not quoted_title then
        quoted_title = trimmed:match("^'([^']+)'")
    end

    if not quoted_title then
        return nil, nil, "Error: :Note expects a quoted title, e.g. :Note \"My title\" [template]"
    end

    local remainder = trimmed:match('^"[^"]+"%s*(.*)') or trimmed:match("^'[^']+'%s*(.*)")
    local template_name = remainder ~= "" and vim.trim(remainder) or nil

    return quoted_title, template_name, nil
end

local function resolve_note_title(args, opts)
    if opts and opts.require_quoted_arg then
        local trimmed = vim.trim(args or "")
        if trimmed == "" then
            return utils.get_note_title(), nil, nil
        end
        return parse_quoted_note_arg(args)
    end

    return utils.get_note_title(args), nil, nil
end

function M.link_note(title)
    local filename = utils.slugify(title) .. ".md"
    local filepath = "./" .. filename

    local markdown_text = "[" .. title .. "](" .. filepath .. ")"

    if vim.fn.expand("%:e") == "md" then
        vim.fn.append(vim.fn.line("."), markdown_text)
    end
end

function M.complete_note(arg_lead, cmd_line, cursor_pos)
    local dir = config.get("field_notes_dir")
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
        if type == "file" and name:match("%.md$") and not name:match("^_") then
            local stem = name:gsub("%.md$", "")
            if stem:find(arg_lead, 1, true) == 1 then
                table.insert(items, stem)
            end
        end
    end

    table.sort(items)
    return items
end

function M.open_note(bang, args, opts)
    local split_cmd = bang and "edit" or "split"
    local vert_prefix = config.get("field_notes_vert") and "vert" or ""
    local title, template_name, title_error = resolve_note_title(args, opts)
    if title_error then
        print(title_error)
        return
    end

    template_name = template_name or config.get("field_notes_default_template")

    if bang then
        M.link_note(title)
    end

    local filename = utils.slugify(title) .. ".md"
    local filepath = config.get("field_notes_dir") .. "/" .. filename

    if template_name and vim.fn.filereadable(filepath) == 1 then
        print("Error: cannot apply template to existing note")
        return
    end
    local cmd = "silent " .. vert_prefix .. " " .. split_cmd .. " " .. vim.fn.fnameescape(filepath)
    vim.cmd(cmd)

    if vim.fn.filereadable(filepath) == 0 then
        local lines
        if template_name then
            lines = templates.apply_template(template_name, title)
        end
        if not lines then
            lines = vim.split("# " .. title .. "\n\n", "\n", { plain = true })
        end
        vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
        vim.bo.buftype = ""
        vim.bo.modified = false
    end

    vim.cmd("lcd " .. vim.fn.expand("%:p:h"))
end

function M.open_notes_dir(bang)
    local buffer_is_empty = vim.fn.bufname("%") == ""
        and vim.fn.line("$") == 1
        and vim.fn.getline(1) == ""
        and not vim.bo.modified

    if buffer_is_empty then
        bang = true
    end

    local split_cmd = bang and "edit" or "split"
    local vert_prefix = config.get("field_notes_vert") and "vert" or ""
    local dir = vim.fn.fnameescape(config.get("field_notes_dir"))

    local cmd = "silent " .. vert_prefix .. " " .. split_cmd .. " " .. dir
    vim.cmd(cmd)
    vim.cmd("silent lcd " .. dir)
end

function M.rename_note()
    local pos = vim.fn.getpos('.')
    vim.fn.cursor(1, 1)
    local line_num = vim.fn.search("^#\\s\\+\\(.*\\)", "n")
    vim.fn.setpos('.', pos)
    if line_num == 0 then
        print("Error: No header found (no line matching '^# ...')")
        return
    end

    local line = vim.fn.getline(line_num)
    local header_text = line:gsub("^#%s+", "")
    local slug = utils.slugify(header_text)

    local current_file = vim.fn.expand("%:p")
    local current_dir = vim.fn.expand("%:p:h")
    local current_ext = vim.fn.expand("%:e")
    local new_filename = slug .. (current_ext == "" and "" or "." .. current_ext)
    local new_path = current_dir .. "/" .. new_filename

    if vim.fn.filereadable(new_path) == 1 and new_path ~= current_file then
        local choice = vim.fn.confirm("File already exists:\n" .. new_path .. "\nOverwrite?", "&Yes\n&No", 2)
        if choice ~= 1 then
            print("Aborted: file not renamed.")
            return
        end
    end

    vim.cmd("write")
    vim.cmd("saveas " .. vim.fn.fnameescape(new_path))
    vim.fn.delete(current_file)
    print("File renamed to: " .. new_filename)
end

function M.grep_notes(pattern)
    local dir = vim.fn.fnameescape(config.get("field_notes_dir"))
    vim.cmd("grep! " .. vim.fn.shellescape(pattern) .. " " .. dir)
    vim.cmd("copen")
end

return M
