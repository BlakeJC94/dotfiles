return {
    "https://github.com/stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff_fix", "ruff_format" },
            sh = { "shfmt" },
            markdown = { "rumdl" },
            sql = { "sqlfluff" },
        },
    },
}
