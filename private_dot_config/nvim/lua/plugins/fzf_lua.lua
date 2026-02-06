return {
    "https://github.com/ibhagwan/fzf-lua",
    opts = {
        winopts = {
            border = "none",
        },
        previewers = {
            man = { cmd = "man %s | col -bx" },
        },
        grep = {
            rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --hidden",
        },
        highlights = {
            actions = {
                ["default"] = function(selected) -- TODO open PR for this action
                    local bufnr = vim.api.nvim_get_current_buf()
                    if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_option(bufnr, "readonly") then
                        return
                    end
                    local cursor = vim.api.nvim_win_get_cursor(0)
                    local row, col = cursor[1] - 1, cursor[2]
                    local results = {}
                    for i = 1, #selected do
                        results[i] = string.gsub(selected[i], "^@", "")
                    end
                    vim.api.nvim_buf_set_text(bufnr, row, col, row, col, results)
                end,
            },
            fzf_opts = {
                ["--no-multi"] = nil,
            },
        },
    },
    keys = {
        { "z=", [[v:count ? v:count . 'z=' : ':FzfLua spell_suggest<CR>']], expr = true },
        { "<C-r><C-r>", "<cmd>FzfLua registers<CR>", mode = "i" },
        { "<Leader><BS>", "<cmd>FzfLua files<CR>", mode = "n" },
        { "<Leader><CR>", "<cmd>FzfLua buffers<CR>", mode = "n" },
        { "<Leader>ff", "<cmd>FzfLua resume<CR>", mode = "n" },
        { "<Leader>fF", "<cmd>FzfLua<CR>", mode = "n" },
        { "<Leader>fb", ":FzfLua buffers<CR>" },
        { "<Leader>fo", ":FzfLua oldfiles cwd_only=true<CR>" }, -- Recently changed files
        { "<Leader>fO", ":FzfLua oldfiles<CR>" }, -- Recently changed files
        { "<Leader>f/", ":FzfLua lgrep_curbuf<CR>" },
        { "<Leader>fg", ":FzfLua live_grep_native<CR>" }, -- Jumping with livegrep
        { "<Leader>fh", ":FzfLua help_tags<CR>" },
        { "<Leader>fH", ":FzfLua man_pages<CR>" },
        { "<Leader>fq", ":FzfLua quickfix<CR>" },
        { "<Leader>fl", ":FzfLua loclist<CR>" },
        { "<Leader>fv", ":FzfLua lsp_document_symbols<CR>" },
    },
}
