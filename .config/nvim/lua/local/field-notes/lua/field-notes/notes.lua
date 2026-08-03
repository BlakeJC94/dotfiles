local config = require("field-notes.config")
local utils = require("field-notes.utils")

local templates = require("field-notes.templates")
local link = require("field-notes.link")
local images = require("field-notes.images")

local M = {}

-- AIDEV-NOTE: :Note accepts a quoted title with template vars and optional template name.
local function parse_quoted_note_arg(args)
    local trimmed = vim.trim(args or "")

    local quoted_title = trimmed:match('^"([^"]+)"')
    if not quoted_title then
        quoted_title = trimmed:match("^'([^']+)'")
    end

    if not quoted_title then
        return nil, nil, 'Error: :Note expects a quoted title, e.g. :Note "My title" [template]'
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

function M.open_note(bang, args, opts)
    local split_cmd = (opts and opts.split) or "edit"
    local title, template_name, title_error = resolve_note_title(args, opts)
    if title_error then
        print(title_error)
        return
    end

    title = templates.render_variables(title, title, opts and opts.template_context)
    template_name = template_name or config.get("field_notes_default_template")

    if bang then
        link.link_note(title)
    end

    local filename = utils.slugify(title) .. ".md"
    local filepath = config.get("field_notes_dir") .. "/" .. filename
    local note_exists_on_disk = vim.fn.filereadable(filepath) == 1
    local note_buffer_exists = vim.fn.bufexists(filepath) == 1

    if template_name and (note_exists_on_disk or note_buffer_exists) then
        template_name = nil
    end
    local cmd = "silent " .. split_cmd .. " " .. vim.fn.fnameescape(filepath)
    vim.cmd(cmd)

    if not note_exists_on_disk and not note_buffer_exists then
        local lines
        if template_name then
            lines = templates.apply_template(template_name, title, opts and opts.template_context)
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

function M.open_notes_dir(opts)
    local split_cmd = (opts and opts.split) or "edit"
    local dir = vim.fn.fnameescape(config.get("field_notes_dir"))

    local cmd = "silent " .. split_cmd .. " " .. dir
    vim.cmd(cmd)
    vim.cmd("silent lcd " .. dir)
end

function M.rename_note()
    local pos = vim.fn.getpos(".")
    vim.fn.cursor(1, 1)
    local line_num = vim.fn.search("^#\\s\\+\\(.*\\)", "n")
    vim.fn.setpos(".", pos)
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
    local dir = vim.fn.fnameescape(config.get("field_notes_dir") or "")
    vim.cmd("grep! " .. vim.fn.shellescape(pattern) .. " " .. dir)
    vim.cmd("copen")
end

function M.list_notes()
    local dir = vim.fn.fnameescape(config.get("field_notes_dir") or "")
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

function M.note_complete(arg_lead, cmd_line, cursor_pos)
    local arg_lead = arg_lead:gsub('^"?', '')
    local items = M.list_notes()
    local filtered = {}
    for _, item in ipairs(items) do
        if item:find(arg_lead, 1, true) == 1 then
            table.insert(filtered, '"' .. item .. '"')
        end
    end
    return filtered
end

--- SETUP ----------------

local note_open_opts = { require_quoted_arg = true }

local function set_command_note()
    vim.api.nvim_create_user_command("Note", function(opts)
        M.open_note(opts.bang, opts.args, note_open_opts)
    end, {
        nargs = "*",
        bang = true,
        complete = function(arg_lead, cmd_line, cursor_pos)
            local has_quoted_arg = cmd_line:match('^%s*Note!?%s+"[^"]*"') or cmd_line:match("^%s*Note!?%s+'[^']*'")
            if has_quoted_arg then
                return templates.template_complete(arg_lead, cmd_line, cursor_pos)
            end
            return M.note_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "Open or create a field note in current window. With !, also insert a link.",
    })
end

local function set_command_note_split()
    vim.api.nvim_create_user_command("NoteSplit", function(opts)
        local split = opts.mods and opts.mods:find("vertical") and "vsplit" or "split"
        M.open_note(opts.bang, opts.args, vim.tbl_extend("force", note_open_opts, { split = split }))
    end, {
        nargs = "*",
        bang = true,
        complete = function(arg_lead, cmd_line, cursor_pos)
            local has_quoted_arg = cmd_line:match('^%s*NoteSplit!?%s+"[^"]*"')
                or cmd_line:match("^%s*NoteSplit!?%s+'[^']*'")
            if has_quoted_arg then
                return templates.template_complete(arg_lead, cmd_line, cursor_pos)
            end
            return M.note_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "Open or create a field note in a split. Use :vert for vertical. With !, also insert a link.",
    })
end

local function set_command_note_v_split()
    vim.api.nvim_create_user_command("NoteVSplit", function(opts)
        M.open_note(opts.bang, opts.args, vim.tbl_extend("force", note_open_opts, { split = "vsplit" }))
    end, {
        nargs = "*",
        bang = true,
        complete = function(arg_lead, cmd_line, cursor_pos)
            local has_quoted_arg = cmd_line:match('^%s*NoteVSplit!?%s+"[^"]*"')
                or cmd_line:match("^%s*NoteVSplit!?%s+'[^']*'")
            if has_quoted_arg then
                return templates.template_complete(arg_lead, cmd_line, cursor_pos)
            end
            return M.note_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "Open or create a field note in a vertical split. With !, also insert a link.",
    })
end

local function set_command_note_rename()
    vim.api.nvim_create_user_command("NoteRename", function()
        M.rename_note()
    end, {
        desc = "Rename note based on heading",
    })
end

local function set_command_note_grep()
    vim.api.nvim_create_user_command("NoteGrep", function(opts)
        M.grep_notes(opts.args)
    end, {
        nargs = 1,
        desc = "Search notes with :grep",
    })
end

local function set_command_note_link()
    vim.api.nvim_create_user_command("NoteLink", function(opts)
        local source_path, title, parse_error = link.parse_note_link_args(opts.args)
        if parse_error then
            print(parse_error)
            return
        end
        link.link_note(title, source_path)
    end, {
        nargs = "*",
        complete = M.note_complete,
        desc = "Insert a markdown link to a field note",
    })
end

local function set_command_note_image()
    vim.api.nvim_create_user_command("NoteImage", function(opts)
        images.move_image(opts.args)
    end, {
        nargs = 1,
        desc = "Copy image into note img dir and insert markdown link",
    })
end

M.setup = function()
    set_command_note()
    set_command_note_split()
    set_command_note_v_split()
    set_command_note_v_split()
    set_command_note_rename()
    set_command_note_grep()
    set_command_note_link()
    set_command_note_image()
end

return M
