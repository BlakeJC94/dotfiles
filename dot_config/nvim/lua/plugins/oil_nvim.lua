return {
    "https://github.com/stevearc/oil.nvim",
    opts = {
        view_options = { show_hidden = true },
    },
    keys = {
        {
            "-",
            function()
                require("oil").open()
            end,
        },
    },
}
