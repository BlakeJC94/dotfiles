config = require("BlakeJC94")

config.set_plugins(
    {
        {
            "nvim-treesitter/nvim-treesitter",
            lazy = false,
            branch = "main",
            build = ":TSUpdate",
            config = config.plugins.nvim_treesitter,
        },
        {
            "neovim/nvim-lspconfig",
            config = config.plugins.nvim_lspconfig,
        },
        {
            "hrsh7th/nvim-cmp",
            dependencies = {
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-cmdline",
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-nvim-lsp-signature-help",
                "hrsh7th/cmp-path",
                "kdheepak/cmp-latex-symbols",
                "lukas-reineke/cmp-under-comparator",
            },
            config = config.plugins.nvim_cmp,
        },
        {
            "ibhagwan/fzf-lua",
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
        },
        {
            "ellisonleao/gruvbox.nvim",
            config = config.plugins.gruvbox_nvim,
        },
        {
            "lewis6991/gitsigns.nvim",
            opts = {
                signcolumn = false,
                numhl      = true,
                linehl     = false,
                current_line_blame = true,
                preview_config = {
                    border = 'none',
                    style = 'minimal',
                    relative = 'cursor',
                },
            },
            keys = {
                {"]c", ":silent Gitsigns next_hunk<CR>"},
                {"[c", ":silent Gitsigns prev_hunk<CR>"},
                {'<Leader>cp',':Gitsigns preview_hunk<CR>'},
                {'<Leader>ch',':Gitsigns toggle_deleted<CR>'},
                {'<Leader>cb', function() require("gitsigns").blame_line({full=true}) end},
                {'<Leader>cf',":diffget //2<CR>"},  -- select left changes
                {'<Leader>cj',":diffget //3<CR>"},  -- select right changes
            },
        },
        {
            "chrisgrieser/nvim-various-textobjs",
            opts = { keymaps = { useDefaults = false } },
            keys = {
                { "av", '<cmd>lua require("various-textobjs").subword("outer")<CR>', mode = { "o", "x" } },
                { "iv", '<cmd>lua require("various-textobjs").subword("inner")<CR>', mode = { "o", "x" } },
            },
        },
        {
            "tpope/vim-fugitive",
            keys={
                {"<Leader>c", "<cmd>call ToggleGstatus()<CR>"},
                {"<Leader>b", ":GBrowse!<CR>", mode="v"},
            },
            config= config.plugins.vim_fugitive,
        },
        {
            "tpope/vim-unimpaired",
            keys={
                {"J", "<Plug>(unimpaired-move-selection-down)gv", mode="v", noremap=false},
                {"K", "<Plug>(unimpaired-move-selection-up)gv", mode="v", noremap=false},
                {"[a", "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-previous)' <bar> endtry <bar> args<CR>", noremap=false},
                {"]a", "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-next)'     <bar> endtry <bar> args<CR>", noremap=false},
                {"[A", "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-first)'    <bar> endtry <bar> args<CR>", noremap=false},
                {"]A", "<cmd>try <bar> exec 'norm \\<Plug>(unimpaired-last)'     <bar> endtry <bar> args<CR>", noremap=false},
            },
        },
        { "tpope/vim-rsi" },
        { "tpope/vim-eunuch" },
        { "tpope/vim-repeat" },
        { "tpope/vim-surround" },
        { "tpope/vim-commentary" },
        { "tpope/vim-dispatch" },
        { "tpope/vim-sleuth" },
        { "tpope/vim-rhubarb" },
        { "tpope/vim-vinegar" },
        { "BlakeJC94/vim-convict" },
        { "brenoprata10/nvim-highlight-colors" },
    }
)
