return {
    "https://github.com/tpope/vim-fugitive",
    lazy = false,
    keys = {
        { "<Leader>b", "<cmd>GBrowse!<CR>", mode = "v" },
        {
            "<Leader>C",
            function()
                local closed = false
                for winnr = 1, vim.fn.winnr("$") do
                    local ft = vim.fn.getwinvar(winnr, "&ft")
                    local status = vim.fn.getwinvar(winnr, "fugitive_status")
                    if ft == "fugitive" and status ~= "" then
                        vim.api.nvim_win_close(vim.fn.win_getid(winnr), true)
                        closed = true
                        break
                    end
                end
                if not closed then
                    vim.cmd("Git")
                end
            end,
        },
        { "<Leader>co", "<cmd>lua resolve_conflict('ours')<CR>" },
        { "<Leader>ct", "<cmd>lua resolve_conflict('theirs')<CR>" },
        { "<Leader>cb", "<cmd>lua resolve_conflict('both')<CR>" },
    },
    config = function()
        -- Statusline
        vim.opt.statusline = "%<%f %h%m%r%{FugitiveStatusline()}%=%{get(b:,'gitsigns_status','')} %-14.(%l,%c%V%) %P"

        -- Autocommands
        local augroup = vim.api.nvim_create_augroup("config_vim_fugitive", { clear = true })
        vim.api.nvim_create_autocmd({ "WinEnter", "BufWritePre", "FileWritePre" }, {
            group = augroup,
            pattern = "*",
            callback = function()
                vim.fn["fugitive#ReloadStatus"]()
            end,
        })


        local function get_conflict()
            local pos = vim.fn.getcurpos()
            local line = pos[2]

            local start_l = vim.fn.search("^<<<<<<<", "bnW")
            if start_l == 0 then
                vim.fn.setpos(".", pos)
                return nil
            end

            vim.fn.cursor(start_l, 1)
            local sep_l = vim.fn.search("^=======$", "nW")
            local end_l = vim.fn.search("^>>>>>>>", "nW")
            vim.fn.setpos(".", pos)

            if sep_l == 0 or end_l == 0 or not (start_l < sep_l and sep_l < end_l) then
                return nil
            end
            if line < start_l or line > end_l then
                return nil
            end

            return {
                total = { start_l, end_l },
                ours = { start_l + 1, sep_l - 1 },
                theirs = { sep_l + 1, end_l - 1 },
            }
        end

        local function resolve_conflict(choice)
            local c = get_conflict()
            if not c then
                return
            end

            local buf = 0
            local start_idx, end_idx = c.total[1] - 1, c.total[2]
            local lines = {}

            if choice == "ours" then
                lines = c.ours[1] > c.ours[2] and {} or vim.api.nvim_buf_get_lines(buf, c.ours[1] - 1, c.ours[2], false)
            elseif choice == "theirs" then
                lines = c.theirs[1] > c.theirs[2] and {}
                    or vim.api.nvim_buf_get_lines(buf, c.theirs[1] - 1, c.theirs[2], false)
            elseif choice == "both" then
                local ours = c.ours[1] > c.ours[2] and {}
                    or vim.api.nvim_buf_get_lines(buf, c.ours[1] - 1, c.ours[2], false)
                local theirs = c.theirs[1] > c.theirs[2] and {}
                    or vim.api.nvim_buf_get_lines(buf, c.theirs[1] - 1, c.theirs[2], false)
                lines = vim.list_extend(ours, theirs)
            end

            vim.api.nvim_buf_set_lines(buf, start_idx, end_idx, false, lines)
        end

        _G.resolve_conflict = resolve_conflict
    end,
}
