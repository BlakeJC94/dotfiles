notes = require("field-notes.notes")

M = {}

local function set_command_log()
    vim.api.nvim_create_user_command("Log", function(opts)
        local offset = tonumber(opts.args) or 0
        local timestamp = os.time() + (offset * 7 * 86400) - ((os.date("%u", os.time()) - 1) * 86400)
        local title = os.date("%Y-W%W: %b %d", timestamp)
        notes.open_note(opts.bang, string.format("%q log", title), {
            require_quoted_arg = true,
            template_context = { reference_timestamp = timestamp },
        })
    end, {
        nargs = "?",
        bang = true,
        desc = "Open weekly log note",
    })
end

local function set_command_this_week()
    vim.api.nvim_create_user_command("ThisWeek", function(opts)
        vim.cmd((opts.bang and "Log!" or "Log") .. " 0")
    end, {
        bang = true,
        desc = "Open this week log",
    })
end

local function set_command_next_week()
    vim.api.nvim_create_user_command("NextWeek", function(opts)
        vim.cmd((opts.bang and "Log!" or "Log") .. " 1")
    end, {
        bang = true,
        desc = "Open next week log",
    })
end

local function set_command_last_week()
    vim.api.nvim_create_user_command("LastWeek", function(opts)
        vim.cmd((opts.bang and "Log!" or "Log") .. " -1")
    end, {
        bang = true,
        desc = "Open last week log",
    })
end

M.setup = function()
    set_command_log()
    set_command_this_week()
    set_command_next_week()
    set_command_last_week()
end

return M
