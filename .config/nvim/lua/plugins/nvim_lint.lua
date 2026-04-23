return {
    "https://github.com/mfussenegger/nvim-lint",
    config = function()
        require("lint").linters_by_ft = {
            make = { "checkmake" },
            markdown = { "write_good" },
            python = { "ruff" },
            sh = { "shellcheck" },
            sql = { "sqlfluff" },
        }

        vim.api.nvim_create_autocmd({ "BufWritePost" }, {
            callback = function()
                require("lint").try_lint()
            end,
        })

    end,
}
