return {
    "https://github.com/stevearc/oil.nvim",
    lazy=false,
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
