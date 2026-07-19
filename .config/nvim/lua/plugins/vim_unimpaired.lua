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
    },
}

