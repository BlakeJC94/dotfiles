return {
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
            "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-next)' <bar> endtry <bar> args<CR>",
            noremap = false,
        },
        {
            "[A",
            "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-first)' <bar> endtry <bar> args<CR>",
            noremap = false,
        },
        {
            "]A",
            "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-last)' <bar> endtry <bar> args<CR>",
            noremap = false,
        },
    },
}

