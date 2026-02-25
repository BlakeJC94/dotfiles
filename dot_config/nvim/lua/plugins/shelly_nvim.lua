return {
    "https://github.com/BlakeJC94/shelly.nvim",
    commands = {
        "Shelly",
        "ShellyCycle",
        "ShellySendCell",
        "ShellySendLine",
        "ShellySendSelection",
    },
    opts = {
        split = {
            direction = "horizontal",
            size = 14,
            position = "bottom",
        },
    },
    keys = {
        {

            "<C-Space>",
            function()
                require("shelly").cycle()
            end,
            mode = { "n", "t" },
        },
        {
            "<C-c>",
            function()
                require("shelly").send_visual_selection()
            end,
            mode = "x",
            desc = "Send visual selection to terminal",
        },
        {
            "<C-c><C-c>",
            function()
                require("shelly").send_current_cell()
            end,
            mode = "n",
            desc = "Send current cell to terminal",
        },
        {
            "<C-c>",
            function()
                vim.o.operatorfunc = "v:lua.require'shelly'.operator_send"
                return "g@"
            end,
            mode = "n",
            expr = true,
            desc = "Send motion to terminal",
        },
        {
            "<Leader>a",
            ":Shelly ",
            mode = "n",
        },
        {
            "<Leader>A",
            function()
                require("shelly").toggle()
            end,
            mode = "n",
        },
    },
}
