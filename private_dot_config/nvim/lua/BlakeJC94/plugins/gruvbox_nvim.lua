return function()
    local gruvbox = require("gruvbox")
    local palette = gruvbox.palette

    for line in io.lines(os.getenv("HOME") .. "/.palette") do
        local key, value = line:match("^(%w+)=\"(.-)\"")
        if key and value then
          palette[key] = value
        end
    end

    local color_midpoint = function(color1, color2, n_midpoints, point_idx)
        n_midpoints = n_midpoints or 1
        point_idx = point_idx or 1

        if n_midpoints < 1 then
            error("Invalid n_midpoints, expected >= 1")
        end
        if point_idx < 1 or point_idx > n_midpoints then
            error("Invalid point_idx")
        end

        local color_coords = {}
        for _, color in ipairs({ color1, color2 }) do
            if type(color) ~= "string" or #color ~= 7 or color:sub(1, 1) ~= "#" then
                error("Invalid color given, expected format '#xxxxxx'")
            end
            color_coords[color] = {
                tonumber("0x" .. color:sub(2):sub(1, 2)),
                tonumber("0x" .. color:sub(2):sub(3, 4)),
                tonumber("0x" .. color:sub(2):sub(5, 6)),
            }
        end

        local delta_x = 1 / (n_midpoints + 1)
        local result = "#"

        for i = 1, 3 do
            local m = color_coords[color2][i] - color_coords[color1][i]
            local c = color_coords[color1][i]
            local step = point_idx * delta_x

            local val = step * m + c
            result = result .. string.format("%02x", math.floor(val + 0.5))
        end

        return result
    end

    local bg_diff_delete = color_midpoint(palette.dark0_hard, palette.neutral_red, 10, 1)
    local bg_diff_add = color_midpoint(palette.dark0_hard, palette.neutral_green, 10, 1)
    local bg_diff_change = color_midpoint(palette.dark0_hard, palette.neutral_blue, 10, 1)
    local bg_diff_text = color_midpoint(palette.dark0_hard, palette.neutral_yellow, 10, 3)

    gruvbox.setup({
        undercurl = true,
        underline = true,
        bold = true,
        italic = {
            strings = false,
            comments = false,
            operators = false,
            folds = false,
        },
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
        contrast = "hard", -- can be "hard" or "soft"
        overrides = {
            NormalFloat = { bg = palette.dark0 },
            SignColumn = { bg = palette.dark0_hard },
            Folded = { bg = palette.dark0 },
            ColorColumn = { bg = palette.dark0 },
            CursorLine = { bg = palette.dark0 },
            CursorLineNr = { bg = palette.dark0 },
            Search = { fg = palette.bright_yellow, bg = palette.dark0 },
            CurSearch = { bg = palette.bright_yellow, fg = palette.dark0 },
            IncSearch = { fg = palette.bright_yellow, bg = palette.dark0 },
            DiffChange = { bg = bg_diff_change, fg = "", reverse = false },
            DiffAdd = { bg = bg_diff_add, fg = "", reverse = false },
            DiffDelete = { bg = bg_diff_delete, fg = "", reverse = false },
            DiffText = { bg = bg_diff_text, fg = "", reverse = false },
            MatchWord = { bg = palette.dark0 },
            MatchParenCur = { bg = palette.dark0 },
            MatchWordCur = { bg = palette.dark0 },
            LocalHighlight = { bg = nil, fg = nil, underline = true },
            SymbolsOutline = { bg = nil, fg = palette.neutral_blue },
            SymbolsOutlineConnector = { bg = nil, fg = palette.neutral_blue },
            healthSuccess = { bg = palette.bright_green, fg = palette.dark0_hard },
            healthError = { bg = palette.bright_red, fg = palette.dark0_hard },
        },
    })

    vim.opt.background = "dark"
    vim.highlight.on_yank({ timeout = 700 })
    vim.cmd("colorscheme gruvbox")
end
