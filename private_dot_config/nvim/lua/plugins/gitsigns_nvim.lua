return {
    "https://github.com/lewis6991/gitsigns.nvim",
    lazy = false,
    opts = {
        signcolumn = false,
        numhl = true,
        linehl = false,
        current_line_blame = true,
        preview_config = {
            border = "none",
            style = "minimal",
            relative = "cursor",
        },
    },
    keys = {
        { "]c", ":silent Gitsigns next_hunk<CR>" },
        { "[c", ":silent Gitsigns prev_hunk<CR>" },
        { "<Leader>cp", ":Gitsigns preview_hunk<CR>" },
        { "<Leader>cd", ":Gitsigns toggle_deleted<CR>" },
        {
            "<Leader>cc",
            function()
                require("gitsigns").blame_line({ full = true })
            end,
        },
        { "<Leader>cq", ":Gitsigns setqflist<CR>" },
        { "<Leader>cQ", ":Gitsigns setloclist<CR>" },
        { "<Leader>cr", ":Gitsigns refresh<CR>" },
        { "<Leader>cw", ":Gitsigns toggle_word_diff<CR>" },
        { "<Leader>cs", ":Gitsigns stage_hunk<CR>", mode = { "n", "v" } },
    },
}
