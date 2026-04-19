return {
    "https://github.com/ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = {
        winopts = { border = "none" },
        grep = { hidden = true },
    },
    keys = {
        { "z=", [[v:count ? v:count . 'z=' : ':FzfLua spell_suggest<CR>']], expr = true },
        { "<C-r><C-r>", "<cmd>FzfLua registers<CR>", mode = "i" },
        { "<Leader><BS>", "<cmd>FzfLua files<CR>", mode = "n" },
        { "<Leader><CR>", "<cmd>FzfLua buffers<CR>", mode = "n" },
        { "<Leader>ff", "<cmd>FzfLua resume<CR>", mode = "n" },
        { "<Leader>fF", "<cmd>FzfLua<CR>", mode = "n" },
        { "<Leader>fd", ":FzfLua lsp_workspace_diagnostics<CR>" },
        { "<Leader>fD", ":FzfLua lsp_document_diagnostics<CR>" },
        { "<Leader>fr", ":FzfLua lsp_references<CR>" },
        { "<Leader>fv", ":FzfLua lsp_document_symbols<CR>" },
        { "<Leader>fa", ":FzfLua lsp_code_actions<CR>" },
        { "<Leader>fo", ":FzfLua oldfiles cwd_only=true<CR>" }, -- Recently changed files
        { "<Leader>fO", ":FzfLua oldfiles<CR>" }, -- Recently changed files
        { "<Leader>f/", ":FzfLua lgrep_curbuf<CR>" },
        { "<Leader>fg", ":FzfLua live_grep_native<CR>" }, -- Jumping with livegrep
        { "<Leader>fh", ":FzfLua help_tags<CR>" },
        { "<Leader>fH", ":FzfLua man_pages<CR>" },
        { "<Leader>fq", ":FzfLua quickfix<CR>" },
        { "<Leader>fl", ":FzfLua loclist<CR>" },
    },
}
