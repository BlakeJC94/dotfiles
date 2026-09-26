local config = require("field-notes.config")
local notes = require("field-notes.notes")

local M = {}

local function define_week_command(name, template_name, desc)
    vim.api.nvim_create_user_command(name, function(opts)
        local offset = tonumber(opts.args) or 0
        local timestamp = os.time() + (offset * 7 * 86400) - ((os.date("%u", os.time()) - 1) * 86400)
        local title = os.date("%Y-W%W: %b %d", timestamp)
        local template = config.get("default_template_" .. template_name) or template_name
        notes.open_note(opts.bang, string.format("%q %s", title, template), {
            require_quoted_arg = true,
            template_context = { reference_timestamp = timestamp },
        })
    end, {
        nargs = "?",
        bang = true,
        desc = desc,
    })
end

M.setup = function()
    define_week_command("Log", "log", "Open weekly log note")
    define_week_command("Journal", "journal", "Open weekly journal note")
end

return M
