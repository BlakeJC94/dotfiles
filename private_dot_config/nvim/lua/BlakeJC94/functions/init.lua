
local M = {}

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

return M
