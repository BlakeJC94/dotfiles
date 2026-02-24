local M = {}

local CONFIG = {
    split = {
        direction = "horizontal",
        size = 16,
        position = "bottom",
    },
    default_name = "scratch",
    scrap_directory = function()
        return vim.fn.getcwd() .. "/scrap/"
    end,
}

--- Plugin state management
--- @class State
--- @field last_filename string Path to the last opened scrap file
local state = {
    last_filename = "",
}

local function get_split_cmd(config)
    local opts = config.split
    local pos = (opts.position == "left" or opts.position == "top") and "topleft" or "botright"
    local dir = opts.direction == "vertical" and " vertical" or ""
    return pos .. dir .. " " .. opts.size .. "split"
end

local function slugify(str)
    local output = str:lower()
    output = output:gsub("%W+", "-")
    output = output:gsub("^-+", "")
    output = output:gsub("-+$", "")
    return output
end

local function get_filepath(ext, scrap_name)
    scrap_name = scrap_name or CONFIG.default_name
    local filename = slugify(scrap_name .. "-" .. vim.fn.strftime("%Y-%m-%d-%H%M")) .. "." .. ext
    local dir = CONFIG.scrap_directory()
    return dir .. filename
end

-- Main Scrap function
function M.scrap(line1, line2, ext, scrap_name)
    -- Get the selected lines from the current buffer before switching
    local selected_lines
    if line1 ~= line2 or line1 ~= vim.fn.line(".") then
        selected_lines = vim.fn.getline(line1, line2)
    end

    -- If no args, try to open last Scrap file
    if scrap_name == nil and state.last_filename ~= "" then
        vim.cmd(get_split_cmd(CONFIG) .. " " .. state.last_filename)
        -- If we have selected lines, copy them to the file
        if (selected_lines ~= nil) and (#selected_lines > 0) then
            vim.fn.setline(1, selected_lines)
        end
        return
    end

    local filename = get_filepath(ext, scrap_name)
    state.last_filename = filename
    vim.cmd(get_split_cmd(CONFIG) .. " " .. filename)

    -- If we have selected lines, copy them to the new file
    if (selected_lines ~= nil) and (#selected_lines > 0) then
        vim.fn.setline(1, selected_lines)
    end
end

function M.setup(opts)
    CONFIG = vim.tbl_deep_extend("force", CONFIG, opts or {})

    vim.api.nvim_create_user_command("Scrap", function(args)
        local ext = args.fargs[1]
        local scrap_name = table.concat(args.fargs, "_", 2, #args.fargs)
        M.scrap(args.line1, args.line2, ext, scrap_name)
    end, {
        range = true,
        nargs = "+",
    })
end

return M
