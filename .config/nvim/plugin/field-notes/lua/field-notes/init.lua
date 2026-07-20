local M = {}

local config = require("field-notes.config")
local utils = require("field-notes.utils")
local notes = require("field-notes.notes")
local images = require("field-notes.images")
local diagrams = require("field-notes.diagrams")
local templates = require("field-notes.templates")

-- Expose all functions through the main module
M.slugify = utils.slugify
M.get_git_dir = utils.get_git_dir
M.get_note_title = utils.get_note_title
M.link_note = notes.link_note
M.open_note = notes.open_note
M.complete_note = notes.complete_note
M.rename_note = notes.rename_note
M.grep_notes = notes.grep_notes
M.move_image = images.move_image
M.new_diagram = diagrams.new_diagram
M.list_templates = templates.list_templates

function M.setup(opts)
    config.setup(opts)

    local note_complete = function(arg_lead, cmd_line, cursor_pos)
        local prefix = arg_lead:match('^"?(.*)')
        local items = M.complete_note(prefix, cmd_line, cursor_pos)
        local quoted = {}
        for _, item in ipairs(items) do
            table.insert(quoted, '"' .. item .. '"')
        end
        return quoted
    end

    local template_complete = function(arg_lead, cmd_line, cursor_pos)
        local items = M.list_templates()
        local filtered = {}
        for _, item in ipairs(items) do
            if item:find(arg_lead, 1, true) == 1 then
                table.insert(filtered, item)
            end
        end
        return filtered
    end

    local note_open_opts = { require_quoted_arg = true }

    vim.api.nvim_create_user_command("Note", function(opts)
        M.open_note(opts.bang, opts.args, note_open_opts)
    end, {
        nargs = "*",
        bang = true,
        complete = function(arg_lead, cmd_line, cursor_pos)
            local has_quoted_arg = cmd_line:match('^%s*Note!?%s+"[^"]*"')
                or cmd_line:match("^%s*Note!?%s+'[^']*'")
            if has_quoted_arg then
                return template_complete(arg_lead, cmd_line, cursor_pos)
            end
            return note_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "Open or create a field note in current window. With !, also insert a link.",
    })

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
                return template_complete(arg_lead, cmd_line, cursor_pos)
            end
            return note_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "Open or create a field note in a split. Use :vert for vertical. With !, also insert a link.",
    })

    vim.api.nvim_create_user_command("NoteVSplit", function(opts)
        M.open_note(opts.bang, opts.args, vim.tbl_extend("force", note_open_opts, { split = "vsplit" }))
    end, {
        nargs = "*",
        bang = true,
        complete = function(arg_lead, cmd_line, cursor_pos)
            local has_quoted_arg = cmd_line:match('^%s*NoteVSplit!?%s+"[^"]*"')
                or cmd_line:match("^%s*NoteVSplit!?%s+'[^']*'")
            if has_quoted_arg then
                return template_complete(arg_lead, cmd_line, cursor_pos)
            end
            return note_complete(arg_lead, cmd_line, cursor_pos)
        end,
        desc = "Open or create a field note in a vertical split. With !, also insert a link.",
    })

    vim.api.nvim_create_user_command("NoteLink", function(opts)
        local title = opts.args:match('^"?(.-)"?$')
        M.link_note(title)
    end, {
        nargs = 1,
        complete = note_complete,
        desc = "Insert a markdown link to a field note",
    })

    -- Log commands
    vim.api.nvim_create_user_command("Log", function(opts)
        local offset = tonumber(opts.args) or 0
        local timestamp = os.time() + (offset * 7 * 86400) - ((os.date("%u", os.time()) - 1) * 86400)
        local title = os.date("%Y-W%W: %b %d", timestamp)
        M.open_note(opts.bang, string.format("%q log", title), {
            require_quoted_arg = true,
            template_context = { reference_timestamp = timestamp },
        })
    end, {
        nargs = "?",
        bang = true,
        desc = "Open weekly log note",
    })

    vim.api.nvim_create_user_command("ThisWeek", function(opts)
        vim.cmd((opts.bang and "Log!" or "Log") .. " 0")
    end, {
        bang = true,
        desc = "Open this week log",
    })

    vim.api.nvim_create_user_command("NextWeek", function(opts)
        vim.cmd((opts.bang and "Log!" or "Log") .. " 1")
    end, {
        bang = true,
        desc = "Open next week log",
    })

    vim.api.nvim_create_user_command("LastWeek", function(opts)
        vim.cmd((opts.bang and "Log!" or "Log") .. " -1")
    end, {
        bang = true,
        desc = "Open last week log",
    })

    -- Utility commands
    vim.api.nvim_create_user_command("Asciiflow", function()
        vim.fn.system("open https://asciiflow.com/")
    end, {
        desc = "Open Asciiflow in browser",
    })

    vim.api.nvim_create_user_command("Image", function(opts)
        M.move_image(opts.args)
    end, {
        nargs = 1,
        desc = "Copy image into note img dir and insert markdown link",
    })

    vim.api.nvim_create_user_command("Diagram", function(opts)
        M.new_diagram(opts.args)
    end, {
        nargs = "?",
        desc = "Create a new diagram",
    })

    vim.api.nvim_create_user_command("Slugify", function(opts)
        print(M.slugify(opts.args))
    end, {
        nargs = 1,
        desc = "Convert text to slug format",
    })

    -- Rename command
    vim.api.nvim_create_user_command("NoteRename", function()
        M.rename_note()
    end, {
        desc = "Rename note based on heading",
    })

    vim.api.nvim_create_user_command("NoteGrep", function(opts)
        M.grep_notes(opts.args)
    end, {
        nargs = 1,
        desc = "Search notes with :grep",
    })
end

return M
