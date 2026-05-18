-- https://github.com/stevearc/conform.nvim#formatters
return {
    "https://github.com/stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff_fix", "ruff_format" },
            sh = { "shfmt" },
            markdown = { "mdformat" },
            sql = { "sqlfluff" },
            java = { "google-java-format" },
            json = { "jq" },
            just = { "just" },
            terraform = { "terraform_fmt" },
            yaml = { "yamlfmt" }
        },
    },
}
