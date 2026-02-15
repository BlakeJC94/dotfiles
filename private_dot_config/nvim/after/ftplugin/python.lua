vim.opt_local.formatoptions:append("r")

vim.api.nvim_create_user_command("RuffFixAll", function()
    vim.lsp.buf.code_action(
        {
            context = { only = { "source.fixAll.ruff" } },
            apply = true
        })
end, { desc = "Run `ruff check --fix` on current buffer" })
