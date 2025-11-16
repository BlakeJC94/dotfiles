return function()
    -- Abbreviations
    vim.cmd([[
        cnoreabbrev <expr> git (getcmdtype() ==# ':' && getcmdline() ==# 'git') ? 'Git' : 'git'
    ]])

    -- Functions
    local function toggle_gstatus()
        local closed = false
        for winnr = 1, vim.fn.winnr('$') do
            local ft = vim.fn.getwinvar(winnr, '&ft')
            local status = vim.fn.getwinvar(winnr, 'fugitive_status')
            if ft == 'fugitive' and status ~= '' then
                vim.api.nvim_win_close(vim.fn.win_getid(winnr), true)
                closed = true
                break
            end
        end
        if not closed then
            vim.cmd('Git')
        end
    end

    -- Expose function globally if needed
    _G.ToggleGstatus = toggle_gstatus

    -- Autocommands
    local augroup = vim.api.nvim_create_augroup("config_vim_fugitive", { clear = true })
    vim.api.nvim_create_autocmd({"WinEnter", "BufWritePre", "FileWritePre"}, {
        group = augroup,
        pattern = "*",
        callback = function()
            vim.fn["fugitive#ReloadStatus"]()
        end
    })

    vim.opt.statusline = "%<%f %h%m%r%{FugitiveStatusline()}%=%{get(b:,'gitsigns_status','')} %-14.(%l,%c%V%) %P"
end
