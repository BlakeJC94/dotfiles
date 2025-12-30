config = require("BlakeJC94")

config.set_plugins({
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        branch = "main",
        build = ":TSUpdate",
        config = config.plugins.nvim_treesitter,
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = config.plugins.nvim_lspconfig,
        keys = {
            {
                "<Leader>=",
                function()
                    vim.lsp.buf.format({ timeout = 1000 })
                end,
            },
            {
                "<Leader>D",
                function()
                    vim.diagnostic.setloclist()
                end,
            },
            {
                "<Leader>d",
                function()
                    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
                end,
            },
        },
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
        "chrisgrieser/nvim-various-textobjs",
        opts = { keymaps = { useDefaults = false } },
        keys = {
            { "av", '<cmd>lua require("various-textobjs").subword("outer")<CR>', mode = { "o", "x" } },
            { "iv", '<cmd>lua require("various-textobjs").subword("inner")<CR>', mode = { "o", "x" } },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
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
            { "]h", ":silent Gitsigns next_hunk<CR>" },
            { "[h", ":silent Gitsigns prev_hunk<CR>" },
            { "<Leader>gp", ":Gitsigns preview_hunk<CR>" },
            { "<Leader>gh", ":Gitsigns toggle_deleted<CR>" },
            {
                "<Leader>gb",
                function()
                    require("gitsigns").blame_line({ full = true })
                end,
            },
            { "<Leader>gB", ":Gitsigns blame<CR>" },
            { "<Leader>gf", ":diffget //2<CR>" }, -- select left changes
            { "<Leader>gj", ":diffget //3<CR>" }, -- select right changes
        },
    },
    { "akinsho/git-conflict.nvim", opts = {} },
    {
        "tpope/vim-fugitive",
        lazy = false,
        keys = {
            { "<Leader>c", "<cmd>lua toggle_gstatus()<CR>" },
            { "<Leader>b", "<cmd>GBrowse!<CR>", mode = "v" },
        },
        config = config.plugins.vim_fugitive,
    },
    {
        "tpope/vim-unimpaired",
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
        "tpope/vim-eunuch",
        lazy = false,
        config = function()
            vim.cmd([[cnoreabbrev ls Ls]])
            vim.cmd([[cnoreabbrev mkdir Mkdir]])
            vim.cmd([[cnoreabbrev rm Remove]])

            vim.api.nvim_create_user_command("Ls", function(opts)
                -- 1. Build the shell command, same as before.
                local shell_cmd = string.format(
                    "(ls -p %s | grep '/$' || true; ls -p %s | grep -v '/$' || true)",
                    opts.args,
                    opts.args
                )

                -- 2. Execute the command and capture its output into a variable.
                --    vim.fn.system() is the Lua way to call Vim's system() function.
                local output = vim.fn.system(shell_cmd)

                -- 3. Print the captured output to the message area.
                --    We use vim.trim() to remove any trailing newline from the shell
                --    output, which prevents an extra blank line from appearing.
                if output ~= nil and not output:match("^%s*$") then
                    print(vim.trim(output))
                else
                    print("[Empty directory]")
                end
            end, {
                nargs = "*", -- Corresponds to -nargs=*
                -- Adding completion is a nice touch. This will complete file/directory names.
                complete = "file",
                -- Add a description for plugins like which-key or for :help
                desc = "List files with directories at the top",
            })
        end,
    },
    { "stevearc/oil.nvim", opts = {}, lazy = false },
    { "tpope/vim-rsi" },
    { "tpope/vim-repeat" },
    { "tpope/vim-surround" },
    -- { "tpope/vim-commentary" },
    { "tpope/vim-sleuth" },
    { "tpope/vim-rhubarb" },
    { "tpope/vim-vinegar" },
    { "BlakeJC94/vim-convict" },
    { "brenoprata10/nvim-highlight-colors" },
    -- {
    --     "tadmccorkle/markdown.nvim",
    --     opts = {},
    -- },
})
