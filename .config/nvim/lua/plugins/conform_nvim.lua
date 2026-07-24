-- https://github.com/stevearc/conform.nvim#formatters
return {
    "https://github.com/stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            css = { "dprint" },
            dockerfile = { "dprint" },
            html = { "dprint" },
            java = { "google-java-format" },
            jinja = { "dprint" },
            json = { "jq" },
            just = { "just" },
            lua = { "stylua" },
            markdown = { "dprint" },
            python = { "ruff_fix", "ruff_format" },
            sh = { "shfmt" },
            sql = { "sqlfluff" },
            terraform = { "terraform_fmt" },
            toml = { "dprint" },
            yaml = { "dprint" },
        },
    },
}
