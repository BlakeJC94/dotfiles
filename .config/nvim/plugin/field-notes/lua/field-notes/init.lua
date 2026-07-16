local M = {}

local config = require("field-notes.config")
local utils = require("field-notes.utils")
local notes = require("field-notes.notes")
local images = require("field-notes.images")
local diagrams = require("field-notes.diagrams")

-- Expose all functions through the main module
M.slugify = utils.slugify
M.get_git_dir = utils.get_git_dir
M.get_note_title = utils.get_note_title
M.get_note_heading = utils.get_note_heading
M.start_note = notes.start_note
M.link_note = notes.link_note
M.initialize_note_if_needed = notes.initialize_note_if_needed
M.open_note = notes.open_note
M.open_notes_dir = notes.open_notes_dir
M.rename_note = notes.rename_note
M.new_diagram = diagrams.new_diagram

function M.setup(opts)
    config.setup(opts)

    vim.api.nvim_create_user_command("Note", function(opts)
        M.open_note(opts.bang, opts.args, { require_quoted_arg = true })
    end, {
        nargs = "*",
        bang = true,
        desc = "Open or create a field note",
    })

    vim.api.nvim_create_user_command("Notes", function(opts)
        M.open_notes_dir(opts.bang)
    end, {
        bang = true,
        desc = "Open the field notes directory",
    })

    -- Log commands
    vim.api.nvim_create_user_command("Log", function(opts)
        local offset = tonumber(opts.args) or 0
        local timestamp = os.time() + (offset * 7 * 86400) - ((os.date("%u", os.time()) - 1) * 86400)
        local title = os.date("%Y-W%W: %b %d", timestamp)
        M.open_note(opts.bang, title)
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
        nargs = "*",
        desc = "Open Asciiflow in browser",
    })

    vim.api.nvim_create_user_command("Diagram", function(opts)
        M.new_diagram(opts.args)
    end, {
        nargs = "*",
        desc = "Create a new diagram",
    })

    vim.api.nvim_create_user_command("Slugify", function(opts)
        print(M.slugify(opts.args))
    end, {
        nargs = "*",
        desc = "Convert text to slug format",
    })

    -- Rename command
    vim.api.nvim_create_user_command("NoteRename", function()
        M.rename_note()
    end, {
        desc = "Rename note based on heading",
    })
end

return M
