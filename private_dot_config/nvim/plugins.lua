local config = require("BlakeJC94")

config.set_plugins({
    {
        "https://github.com/nvim-treesitter/nvim-treesitter",
        lazy = false,
        branch = "main",
        build = ":TSUpdate",
        config = config.plugins.nvim_treesitter,
    },
    {
        "https://github.com/neovim/nvim-lspconfig",
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
        "https://github.com/hrsh7th/nvim-cmp",
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
    },
    {
        "https://github.com/ellisonleao/gruvbox.nvim",
        config = config.plugins.gruvbox_nvim,
    },
    {
        "https://github.com/chrisgrieser/nvim-various-textobjs",
        opts = { keymaps = { useDefaults = false } },
        keys = {
            { "av", '<cmd>lua require("various-textobjs").subword("outer")<CR>', mode = { "o", "x" } },
            { "iv", '<cmd>lua require("various-textobjs").subword("inner")<CR>', mode = { "o", "x" } },
        },
    },
    {
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
    { "https://github.com/akinsho/git-conflict.nvim", opts = {} },
    {
        "https://github.com/tpope/vim-fugitive",
        lazy = false,
        keys = {
            { "<Leader>c", "<cmd>lua toggle_gstatus()<CR>" },
            { "<Leader>b", "<cmd>GBrowse!<CR>", mode = "v" },
        },
        config = config.plugins.vim_fugitive,
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
        config = function()
            vim.cmd([[cnoreabbrev mkdir Mkdir]])
            vim.cmd([[cnoreabbrev rm Remove]])
        end,
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
    { "https://github.com/tpope/vim-sleuth" },
    { "https://github.com/tpope/vim-rhubarb" },
    { "https://github.com/BlakeJC94/vim-convict" },
    { "https://github.com/brenoprata10/nvim-highlight-colors" },
    { "https://github.com/Mofiqul/trld.nvim" },
    {
        "mozanunal/sllm.nvim",
        lazy = false,
        opts = {
            default_model = "default",
            keymaps = false,
        },
        config = function()

            -- Chat functions
            vim.api.nvim_create_user_command("LLM", function()
                require("sllm").ask_llm()
            end, { range = true })
            vim.api.nvim_create_user_command("LLMNewChat", function()
                require("sllm").new_chat()
            end, {})
            vim.api.nvim_create_user_command("LLMCancel", function()
                require("sllm").cancel()
            end, {})
            vim.api.nvim_create_user_command("LLMHistory", function()
                require("sllm").browse_history()
            end, {})

            -- Context functions
            vim.api.nvim_create_user_command("LLMAddContext", function()
                require("sllm").add_context()
            end, { range = true })
            vim.api.nvim_create_user_command("LLMAddUrl", function()
                require("sllm").add_url_to_ctx()
            end, {})
            vim.api.nvim_create_user_command("LLMAddOutput", function()
                require("sllm").add_cmd_out_to_ctx()
            end, {})
            vim.api.nvim_create_user_command("LLMAddTool", function()
                require("sllm").add_tool_to_ctx()
            end, {})

            -- UI functions
            vim.api.nvim_create_user_command("LLMToggle", function()
                require("sllm").toggle_llm_buffer()
            end, {})
            vim.api.nvim_create_user_command("LLMFocus", function()
                require("sllm").focus_llm_buffer()
            end, {})
            vim.api.nvim_create_user_command("LLMCommand", function()
                require("sllm").run_command()
            end, {})

            -- Copy functions
            vim.api.nvim_create_user_command("LLMCopyResponse", function()
                require("sllm").copy_last_response()
            end, {})
            vim.api.nvim_create_user_command("LLMCopyCodeLast", function()
                require("sllm").copy_last_code_block()
            end, {})
            vim.api.nvim_create_user_command("LLMCopyCodeFirst", function()
                require("sllm").copy_first_code_block()
            end, {})
        end,
        keys = {
            {
                "<Leader>s",
                function()
                    require("sllm").ask_llm()
                end,
                mode = { "n", "v" },
            },
            {
                "<Leader>S",
                function()
                    require("sllm").toggle_llm_buffer()
                end,
                mode = "n",
            },
        },
    },
})
