vim.opt_local.formatoptions:append("r")

vim.api.nvim_create_user_command("RuffFixAll", function()
    vim.lsp.buf.code_action({
        context = { only = { "source.fixAll.ruff" } },
        apply = true,
    })
end, { desc = "Run `ruff check --fix` on current buffer" })

-- Dictionary to Keyword arguments
local function dtk(line1, line2)
    vim.cmd(string.format('%d,%ds/^\\(\\s*\\)"\\(.*\\)"\\s*:\\s*\\(.*\\),\\s*$/\\1\\2=\\3,/', line1, line2))
end
vim.api.nvim_create_user_command("DTK", function(opts)
    dtk(opts.line1, opts.line2)
end, {
    range = true,
})

-- Keyword arguments to Dictionary
local function ktd(line1, line2)
    vim.cmd(string.format('%d,%ds/^\\(\\s*\\)\\(.*\\)\\s*=\\s*\\(.*\\)\\s*$/\\1"\\2": \\3,/', line1, line2))
end
vim.api.nvim_create_user_command("KTD", function(opts)
    ktd(opts.line1, opts.line2)
end, {
    range = true,
})

-- Sync file changes from Marimo notebooks
vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*",
    callback = function(args)
        local buf = args.buf
        local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
        if lines[1] ~= "import marimo" then
            return
        end

        local filepath = vim.api.nvim_buf_get_name(buf)
        if filepath == "" then
            return
        end

        local initial_mtime = vim.fn.getftime(filepath)
        local foldlevel = vim.opt.foldlevel:get()
        local timer = vim.uv.new_timer()

        timer:start(
            0,
            200,
            vim.schedule_wrap(function()
                if vim.fn.bufexists(buf) == 0 then
                    timer:stop()
                    return
                end

                local current_mtime = vim.fn.getftime(filepath)
                if current_mtime > initial_mtime then
                    timer:stop()
                    vim.cmd("buffer " .. buf .. " | edit! | echo 'Reloaded Marimo notebook'")
                    vim.opt.foldlevel = foldlevel
                end
            end)
        )

        vim.defer_fn(function()
            timer:stop()
        end, 2500)
    end,
})
