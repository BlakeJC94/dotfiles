local M = {}

-- Create parent directories on write if they don't exist
M.setup_create_parent_dirs = function()
    vim.api.nvim_create_augroup("create_dirs_on_write", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePre", "FileWritePre" }, {
        group = "create_dirs_on_write",
        callback = function()
            local dir = vim.fn.expand("<afile>:p:h")
            if vim.fn.isdirectory(dir) == 0 and not dir:match(":") then
                local choice = vim.fn.confirm('Create directory "' .. dir .. '"?', "&Yes\n&No", 1)
                if choice == 1 then
                    vim.fn.mkdir(dir, "p")
                end
            end
        end,
    })
end

-- Trim trailing whitespace and excess newlines on write
M.setup_trim_spaces = function()
    vim.api.nvim_create_augroup("trim_spaces_on_write", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = "trim_spaces_on_write",
        callback = function()
            -- Don't retab for make files (they use tabs)
            if vim.tbl_contains({ "make" }, vim.bo.filetype) == false then
                vim.cmd("retab")
            end

            -- Save window state
            local winstate = vim.fn.winsaveview()

            -- Remove trailing spaces
            vim.cmd("keeppatterns %s/\\s\\+$//e")

            -- Remove excess trailing newlines
            vim.cmd("keeppatterns %s/\\n\\n\\+\\%$/\\r/e")

            -- Restore window state
            vim.fn.winrestview(winstate)
        end,
    })
end

-- Set buffer options for info/help buffers
M.setup_info_buffer_opts = function()
    vim.api.nvim_create_augroup("info_buffer_opts", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = "info_buffer_opts",
        pattern = { "help", "man", "git", "ale-info", "fugitive", "netrw" },
        callback = function()
            vim.opt_local.colorcolumn = ""
            vim.opt_local.spell = false
            vim.opt_local.foldlevel = 99
            vim.opt_local.formatoptions:remove("t")
            vim.keymap.set("n", "K", function()
                local word = vim.fn.expand("<cword>")
                vim.cmd("help " .. word)
            end, { buffer = true, silent = true })
        end,
    })
end

-- Jump to last edit position when opening a file
M.setup_jump_to_last_edit = function()
    vim.api.nvim_create_augroup("jump_to_last_edit", { clear = true })
    vim.api.nvim_create_autocmd("BufReadPost", {
        group = "jump_to_last_edit",
        callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if mark[1] > 0 and mark[1] <= lcount then
                pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
        end,
    })
end

return M
