return {
    "https://github.com/arborist-ts/arborist.nvim",
    lazy = false,
    opts = {
        update_cadence = "weekly",
        install_popular = true,
        -- https://github.com/arborist-ts/arborist.nvim/blob/main/lua/arborist/init.lua#L133
        -- {
        --     "bash", "c", "cpp", "css", "diff", "dockerfile", "go", "html",
        --     "ini", "java", "javascript", "json", "latex", "lua", "make",
        --     "markdown", "markdown_inline", "python", "regex", "ruby", "rust",
        --     "toml", "tsx", "typescript", "vim", "vimdoc", "xml", "yaml",
        -- }
        ensure_installed = {
            "comment",
            "csv",
            "git_config",
            "gitcommit",
            "gitignore",
            "jinja",
            "jinja_inline",
            "jq",
            "julia",
            "just",
            "r",
            "sql",
            "terraform",
            "zsh",
        },
    },
}
