vim.opt_local.formatoptions:append('r')

vim.api.nvim_create_autocmd("LspRequest", {
    callback = function(args)
        local client_name = vim.lsp.get_client_by_id(args.data.client_id).name
        local method = args.data.request.method

        if client_name == "ruff" and method == "textDocument/formatting" then
            vim.lsp.buf.code_action({ context = { only = { "source.fixAll.ruff" } }, apply = true })
        end
    end,
})
