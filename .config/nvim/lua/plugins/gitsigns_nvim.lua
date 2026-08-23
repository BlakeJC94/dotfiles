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
        { "<Leader>cr", ":Gitsigns refresh<CR>" },
        { "<Leader>cd", ":Gitsigns toggle_deleted<CR>" },
        { "<Leader>cp", ":Gitsigns preview_hunk_inline<CR>" },
        { "<Leader>cP", ":Gitsigns preview_hunk<CR>" },
        { "<Leader>cq", ":Gitsigns setqflist<CR>" },
        { "<Leader>cQ", ":Gitsigns setloclist<CR>" },
        { "<Leader>cs", ":Gitsigns stage_hunk<CR>", mode = { "n", "v" } },
        { "<Leader>cu", ":Gitsigns reset_hunk<CR>", mode = { "n", "v" } },
        { "<Leader>cw", ":Gitsigns toggle_word_diff<CR>" },
        {
            "<Leader>cl",
            function()
                require("gitsigns").blame_line({ full = true })
            end,
        },
        { "[c", ":silent Gitsigns prev_hunk<CR>" },
        { "]c", ":silent Gitsigns next_hunk<CR>" },
    },
}
