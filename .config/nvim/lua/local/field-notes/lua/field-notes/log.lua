local config = require("field-notes.config")
local notes = require("field-notes.notes")
local templates = require("field-notes.templates")
local utils = require("field-notes.utils")

local M = {}

local function get_week_details(opts, template_name)
    local offset = tonumber(opts.args) or 0
    local now = os.time()
    local timestamp = now + (offset * 7 * 86400) - ((os.date("%u", now) - 1) * 86400)
    local title = os.date("%Y-W%W: %b %d", timestamp)
    local template = config.get("default_template_" .. template_name) or template_name
    local context = { reference_timestamp = timestamp }
    return title, template, context
end

local function define_week_command(name, template_name, desc)
    vim.api.nvim_create_user_command(name, function(opts)
        local title, template, context = get_week_details(opts, template_name)
        notes.open_note(opts.bang, string.format("%q -t %s", title, template), {
            require_quoted_arg = true,
            template_context = context,
        })
    end, {
        nargs = "?",
        bang = true,
        desc = desc,
    })
end

local function define_week_create_command(name, template_name, desc)
    vim.api.nvim_create_user_command(name, function(opts)
        local title, selected_template, context = get_week_details(opts, template_name)
        local lines = templates.apply_template(selected_template, title, context)
        if lines then
            for _, line in ipairs(lines) do
                local heading = line:match("^#%s+(.*)")
                if heading then
                    title = heading
                    break
                end
            end
        else
            title = templates.render_variables(title, title, context)
            lines = vim.split("# " .. title .. "\n\n", "\n", { plain = true })
        end

        local filename = utils.slugify(title) .. ".md"
        local filepath = vim.fn.expand(config.get("field_notes_dir") .. "/" .. filename)
        if vim.uv.fs_stat(filepath) then
            print("Not created; file already exists: " .. filepath)
            return
        end
        if vim.fn.writefile(lines, filepath) ~= 0 then
            print("Error creating file: " .. filepath)
            return
        end
        print("Created: " .. filepath)
    end, {
        nargs = "?",
        desc = desc,
    })
end

M.setup = function()
    define_week_command("Log", "log", "Open weekly log note")
    define_week_command("Journal", "journal", "Open weekly journal note")
    define_week_create_command("LogCreate", "log", "Create weekly log file without opening it")
    define_week_create_command("JournalCreate", "journal", "Create weekly journal file without opening it")
end

return M
