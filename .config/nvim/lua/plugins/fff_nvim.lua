return {
    "https://github.com/dmtrKovalenko/fff.nvim",
    lazy = false,
    build = function()
        -- downloads a prebuilt binary or falls back to cargo build
        require("fff.download").download_or_build_binary()
    end,
    opts = {
        debug = {
            enabled = true,
            show_scores = true,
        },
    },
    keys = {
        {
            "<Leader>FF",
            function()
                require("fff").find_files()
            end,
            desc = "FFFind files",
        },
        {
            "<Leader>FG",
            function()
                require("fff").live_grep()
            end,
            desc = "LiFFFe grep",
        },
        {
            "<Leader>FG",
            function()
                require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
            end,
            desc = "Live fffuzy grep",
        },
        {
            "<Leader>FC",
            function()
                require("fff").live_grep({ query = vim.fn.expand("<cword>") })
            end,
            desc = "Search current word",
        },
    },
}
