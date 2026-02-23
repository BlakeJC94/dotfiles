return {
    {
        dir = vim.fn.stdpath("config") .. "/plugin/field-notes",
        lazy = false,
        opts = {
            field_notes_vert = true,
            field_notes_dir = vim.fn.expand("~/Workspace/field-notes"),
            blog_content_dir = vim.fn.expand("~/Workspace/repos/blog/content"),
        },
        keys = {
            { "<Leader>n", ":Note<CR>" },
            { "<Leader>N", ":Notes<CR>" },
        },
    },
    {
        dir = vim.fn.stdpath("config") .. "/plugin/python-scrap",
    },
    {
        dir = vim.fn.stdpath("config") .. "/plugin/llm",
        opts = {
            split = {
                direction = "horizontal",
                size = 14,
                position = "bottom",
            },
        },
    },
    {
        "https://github.com/chrisgrieser/nvim-various-textobjs",
        lazy = false,
        opts = { keymaps = { useDefaults = false } },
        keys = {
            { "av", '<cmd>lua require("various-textobjs").subword("outer")<CR>', mode = { "o", "x" } },
            { "iv", '<cmd>lua require("various-textobjs").subword("inner")<CR>', mode = { "o", "x" } },
        },
    },
    {
        "https://github.com/tpope/vim-unimpaired",
        lazy = false,
        keys = {
            {
                "J",
                "<Plug>(unimpaired-move-selection-down)gv",
                mode = "v",
                noremap = false,
            },
            {
                "K",
                "<Plug>(unimpaired-move-selection-up)gv",
                mode = "v",
                noremap = false,
            },
            {
                "[a",
                "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-previous)' <bar> endtry <bar> args<CR>",
                noremap = false,
            },
            {
                "]a",
                "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-next)'     <bar> endtry <bar> args<CR>",
                noremap = false,
            },
            {
                "[A",
                "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-first)'    <bar> endtry <bar> args<CR>",
                noremap = false,
            },
            {
                "]A",
                "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-last)'     <bar> endtry <bar> args<CR>",
                noremap = false,
            },
        },
    },
    {
        "https://github.com/tpope/vim-eunuch",
        lazy = false,
    },
    {
        "https://github.com/stevearc/oil.nvim",
        opts = {
            view_options = { show_hidden = true },
        },
        lazy = false,
        keys = {
            {
                "-",
                function()
                    require("oil").open()
                end,
            },
        },
    },
    { "https://github.com/tpope/vim-rsi" },
    { "https://github.com/tpope/vim-repeat" },
    { "https://github.com/tpope/vim-surround" },
    { "https://github.com/tpope/vim-rhubarb" },
    { "https://github.com/BlakeJC94/vim-convict" },
    { "https://github.com/brenoprata10/nvim-highlight-colors" },
    { "https://github.com/Mofiqul/trld.nvim" },
    {
        "BlakeJC94/shelly.nvim",
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
    },
}
