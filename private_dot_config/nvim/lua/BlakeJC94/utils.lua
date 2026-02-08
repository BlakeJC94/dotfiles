local M = {}

-- Configure custom fold text
M.set_custom_fold_text = function()
    vim.opt.foldtext = "v:lua.BlakeJC94.custom_fold_text()"
end

-- Set ripgrep as grep backend if available
M.set_grep_rg_backend = function()
    if vim.fn.executable("rg") == 1 then
        vim.opt.grepprg = "rg --vimgrep --smart-case"
        vim.opt.grepformat = "%f:%l:%c:%m"
    end
end

-- Set undo break points in insert mode for better undo granularity
M.set_undo_maps = function()
    for _, mark in pairs({ ".", ",", "!", "?", "(", ")", "[", "]", "{", "}", "<", ">", '"', "'" }) do
        vim.keymap.set("i", mark, mark .. "<C-g>u")
    end
end

-- Disable shift/alt arrow keys in normal mode
M.set_arrow_maps = function()
    for _, mod in pairs({ "S-", "A-" }) do
        for _, dir in pairs({ "Left", "Down", "Up", "Right" }) do
            vim.keymap.set("n", "<" .. mod .. dir .. ">", "")
        end
    end
end

return M
