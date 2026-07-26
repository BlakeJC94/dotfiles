return {
    dir = vim.fn.stdpath("config") .. "/lua/local/fences",
    ft = "markdown",
    opts = { bg = "#282828" },
    keys = {
        {
            "ic",
            function()
                require("fences").select_fenced_code(true)
            end,
            buffer = 0,
            mode = { "x", "o" },
        },
        {
            "ac",
            function()
                require("fences").select_fenced_code(false)
            end,
            buffer = 0,
            mode = { "x", "o" },
        },
    },
}
