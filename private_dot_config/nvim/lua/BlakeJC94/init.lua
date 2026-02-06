M = {}

M.custom_fold_text = function()
    local line = vim.fn.getline(vim.v.foldstart)

    local indent_str = string.rep(" ", vim.fn.indent(vim.v.foldstart - 1))
    local fold_str = indent_str .. line .. string.rep(" ", vim.bo.textwidth)

    local fold_size = vim.v.foldend - vim.v.foldstart + 1
    local fold_size_str = " (" .. fold_size .. ") "

    return string.sub(fold_str, 0, vim.bo.textwidth - #fold_size_str) .. fold_size_str
end

M.set_custom_fold_text = function()
    vim.opt.foldtext = "v:lua.require('BlakeJC94').custom_fold_text()"
end

M.set_grep_rg_backend = function()
    if vim.fn.executable("rg") == 1 then
        vim.opt.grepprg = "rg --vimgrep --smart-case"
        vim.opt.grepformat = "%f:%l:%c:%m"
    end
end

M.toggle_quickfix_list = function()
    local has_qf = #vim.fn.filter(vim.fn.getwininfo(), "v:val.quickfix") > 0

    if has_qf then
        pcall(vim.cmd.cclose)
    else
        local ok = pcall(vim.cmd.copen)
        if not ok then
            vim.notify("No quickfix list available", vim.log.levels.WARN)
        end
    end
end

M.toggle_local_list = function()
    local has_loc = #vim.fn.filter(vim.fn.getwininfo(), "v:val.loclist") > 0

    if has_loc then
        pcall(vim.cmd.lclose)
    else
        local ok = pcall(vim.cmd.lopen)
        if not ok then
            vim.notify("No location list available", vim.log.levels.WARN)
        end
    end
end

M.set_undo_maps = function()
    for _, mark in pairs({ ".", ",", "!", "?", "(", ")", "[", "]", "{", "}", "<", ">", '"', "'" }) do
        vim.keymap.set("i", mark, mark .. "<C-g>u")
    end
end

M.set_arrow_maps = function()
    for _, mod in pairs({ "S-", "A-" }) do
        for _, dir in pairs({ "Left", "Down", "Up", "Right" }) do
            vim.keymap.set("n", "<" .. mod .. dir .. ">", "" )
        end
    end
end

return M
