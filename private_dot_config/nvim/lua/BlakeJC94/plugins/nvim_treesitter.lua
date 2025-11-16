return function()
    local treesitter = require("nvim-treesitter")
    treesitter.setup({
        install_dir = vim.fn.stdpath("data") .. "/treesitter",
    })
    treesitter.install({ "python", "lua", "markdown", "markdown_inline", "sql" })
    vim.api.nvim_create_autocmd("FileType", {
       pattern = { "python,lua,markdown,sql" },
       callback = function()
        vim.treesitter.start()
       end,
    })
end
