return function()
    local treesitter = require("nvim-treesitter")

    treesitter.setup({
        install_dir = vim.fn.stdpath("data") .. "/treesitter",
    })

    local langauges_to_install = {
        "bash",
        "comment",
        "csv",
        "dockerfile",
        "git_config",
        "gitcommit",
        "gitignore",
        "html",
        "html_tags",
        "jinja",
        "jinja_inline",
        "jq",
        "json",
        "julia",
        "just",
        "lua",
        "make",
        "markdown",
        "markdown_inline",
        "python",
        "r",
        "regex",
        "sql",
        "terraform",
        "toml",
        "yaml",
        "zsh",
    }

    treesitter.install(langauges_to_install)

    vim.api.nvim_create_autocmd("FileType", {
        pattern = { table.concat(langauges_to_install, ",") },
        callback = function()
            vim.treesitter.start()
        end,
    })
end
