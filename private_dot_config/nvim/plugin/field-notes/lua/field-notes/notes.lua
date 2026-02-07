local config = require("field-notes.config")
local utils = require("field-notes.utils")
local M = {}

function M.start_note(...)
    local title = utils.get_note_title(...)
    local filename = utils.slugify(title) .. ".md"
    local filepath = config.get("field_notes_dir") .. "/" .. filename
    return filepath
end

function M.link_note(...)
    local args = { ... }
    local title = utils.get_note_title(...)
    local filename = utils.slugify(title) .. ".md"
    local filepath = "./" .. filename

    local markdown_text = "![" .. title .. "](" .. filepath .. ")"

    if vim.fn.expand("%:e") == "md" then
        vim.fn.append(vim.fn.line("."), markdown_text)
    end
end

function M.initialize_note_if_needed(...)
    if vim.fn.filereadable(vim.fn.expand("%")) == 0 then
        local heading = utils.get_note_heading(...)
        local lines = vim.split(heading, "\n", { plain = true })
        vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
        vim.bo.buftype = ""
        vim.bo.modified = false
    end
end

function M.open_note(bang, args)
    local split_cmd = bang and "edit" or "split"
    local vert_prefix = config.get("field_notes_vert") and "vert" or ""

    if bang then
        M.link_note(args)
    end

    local note_path = M.start_note(args)
    local cmd = "silent " .. vert_prefix .. " " .. split_cmd .. " " .. vim.fn.fnameescape(note_path)
    vim.cmd(cmd)

    M.initialize_note_if_needed(args)
    vim.cmd("lcd " .. vim.fn.expand("%:p:h"))
    print(vim.fn.expand("%:p"))
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
    local line_num = vim.fn.search("^#\\s\\+\\(.*\\)", "n")
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

return M
