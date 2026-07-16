local config = require("field-notes.config")
local utils = require("field-notes.utils")
local M = {}

-- AIDEV-NOTE: :Note accepts exactly one quoted title argument.
local function parse_quoted_note_arg(args)
    local trimmed = vim.trim(args or "")

    if trimmed:match('^"[^"]+"$') then
        return trimmed:sub(2, -2)
    end

    if trimmed:match("^'[^']+'$") then
        return trimmed:sub(2, -2)
    end

    return nil, "Error: :Note expects exactly one quoted title, e.g. :Note \"My title\""
end

local function resolve_note_title(args, opts)
    if opts and opts.require_quoted_arg then
        return parse_quoted_note_arg(args)
    end

    return utils.get_note_title(args)
end

function M.link_note(title)
    local filename = utils.slugify(title) .. ".md"
    local filepath = "./" .. filename

    local markdown_text = "![" .. title .. "](" .. filepath .. ")"

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
        if type == "file" and name:match("%.md$") then
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
    local title, title_error = resolve_note_title(args, opts)
    if title_error then
        print(title_error)
        return
    end

    if bang then
        M.link_note(title)
    end

    local filename = utils.slugify(title) .. ".md"
    local filepath = config.get("field_notes_dir") .. "/" .. filename
    local cmd = "silent " .. vert_prefix .. " " .. split_cmd .. " " .. vim.fn.fnameescape(filepath)
    vim.cmd(cmd)

    -- Initialize heading in newly created notes.
    if vim.fn.filereadable(filepath) == 0 then
        local heading = "# " .. title .. "\n\n"
        local lines = vim.split(heading, "\n", { plain = true })
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
