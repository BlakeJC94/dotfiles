return {
    dir = vim.fn.stdpath("config") .. "/lua/local/lists-md",
    ft = "markdown",
    keys = {
        {
            "<C-,>",
            function()
                require("lists-md").indent_item_left()
            end,
            mode = { "n", "i" },
        },
        {
            "<C-.>",
            function()
                require("lists-md").indent_item_right()
            end,
            mode = { "n", "i" },
        },
        {
            "<C-;>",
            function()
                require("lists-md").toggle_checkbox()
            end,
            mode = { "n", "i" },
        },
        {
            "<CR>",
            function()
                return require("lists-md").next_item()
            end,
            mode = { "n", "i" },
            expr = true,
        },
    },
}
