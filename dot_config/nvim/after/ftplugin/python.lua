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
