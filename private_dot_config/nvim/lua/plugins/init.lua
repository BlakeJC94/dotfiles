return {
    {
        name = "BlakeJC94",
        dir = vim.fn.stdpath("config"),
        lazy = false,
        opts = {},
        config = function()
            m = require("BlakeJC94")
            m.set_custom_fold_text()
            m.set_undo_maps()
            m.set_arrow_maps()
        end,
        keys = {
            -- Better jumplist for large line steps (and step through visual lines with j/k)
            {
                "j",
                [[(v:count > 5 ? 'm`' . v:count : 'g') . 'j']],
                expr = true,
            },
            {
                "k",
                [[(v:count > 5 ? 'm`' . v:count : 'g') . 'k']],
                expr = true,
            },
            -- gV: Visually select last pasted block (like gv)
            { "gV", "`[v`]" },
            -- gF: create new file at filename over cursor
            { "gF", "<cmd>e <c-r><c-f><CR>" },
            -- Make {/} don't change the jump list
            { "{",  ":<C-u>keepjumps norm! {<CR>" },
            { "}",  ":<C-u>keepjumps norm! }<CR>" },
            -- Prevent x and s from overriding what's in the clipboard
            { "x",  '"_x' },
            { "X",  '"_X' },
            { "s",  '"_s' },
            -- Open folds when flicking through search matches
            { "n",  "nzv" },
            { "N",  "Nzv" },
            -- Remap q and Q to stop polluting registers accidentally!
            { "q",  "gw" },
            { "Q",  "q" },
            -- Maintain Visual Mode after >/</= actions
            {
                "<",
                "<gv",
                mode = "v",
            },
            {
                ">",
                ">gv",
                mode = "v",
            },
            {
                "=",
                "=gv",
                mode = "v",
            },
            -- Swap p and P to stop losing register contents by pasting over
            {
                "p",
                '"_dp',
                mode = "v",
            },
            {
                "P",
                '"_dP',
                mode = "v",
            },
            -- C-s : Quickly guess correct spelling errors (undoable)
            {
                "<C-s>",
                "<C-g>u<Esc>[s1z=`]i<C-g>u",
                mode = "i",
                remap = false,
            },
            {
                "<C-s>",
                "i<C-g>u<Esc>[s1z=`]",
                remap = false,
            },
            -- C-x : Execute
            {
                "<Leader>x",
                "<C-g>u:.!sh<CR>`]",
                remap = false,
            },
            {
                "<Leader>x",
                "<C-g>u:!sh<CR>`]",
                mode = "x",
                remap = false,
            },
            -- Stop accidentally opening help in insert mode
            {
                "<F1>",
                "",
                mode = "i",
            },
            -- Use unused arrow keys
            {
                "<Left>",
                "[",
                remap = true,
            },
            {
                "<Right>",
                "]",
                remap = true,
            },
            {
                "<Up>",
                "[",
                remap = true,
            },
            {
                "<Down>",
                "]",
                remap = true,
            },
            -- Fkey maps
            {
                "<F1>",
                ":setl relativenumber!<CR>:setl relativenumber?<CR>",
                silent = false,
            },
            {
                "<F2>",
                ":setl number!<CR>:setl number?<CR>",
                silent = false,
            },
            {
                "<F3>",
                ":setl wrap!<CR>:setl wrap?<CR>",
                silent = false,
            },
            {
                "<F4>",
                ":setl spell!<CR>:setl spell?<CR>",
                silent = false,
            },
            {
                "<F5>",
                ":checktime<CR>",
                silent = false,
            },
            {
                "<F6>",
                ":wincmd =<CR>",
                silent = false,
            },
            -- Resize split maps
            { "<C-Left>",      ":wincmd 8<<CR>" },
            { "<C-Up>",        ":wincmd 4+<CR>" },
            { "<C-Down>",      ":wincmd 4-<CR>" },
            { "<C-Right>",     ":wincmd 8><CR>" },
            -- Vim Tab controls
            { "<Leader>t",     ":tabedit %<CR>" },
            { "<Leader>n",     ":tabnext<CR>" },
            { "<Leader>p",     ":tabnext<CR>" },
            { "<Leader>N",     ":+tabmove<CR>" },
            { "<Leader>P",     ":-tabmove<CR>" },
            -- Select all
            { "<Leader>e",     "ggVG" },
            -- Leader maps
            { "<Leader><Tab>", "<C-^>" },        -- Last file
            { "<Leader>O",     ":%bd|e#|bd# <CR>" }, -- Clear buffers
            {
                "<Leader>q",
                function()
                    require("BlakeJC94").toggle_quickfix_list()
                end,
            },
            {
                "<Leader>Q",
                function()
                    require("foo").toggle_local_list()
                end,
            },
            { "<Leader>;", "<cmd>edit $MYVIMRC | lcd %:p:h<CR>" },
            { "<Leader>.", "<cmd>lcd %:p:h | echo 'Changed local dir to ' . getcwd()<CR>" },
            { "<Leader>,", "<cmd>cd %:p:h | echo 'Changed dir to ' . getcwd()<CR>" },
            {
                "<Leader>/",
                "<cmd>cd `git rev-parse --show-toplevel` \\| echo 'Changed dir to project root: ' . getcwd()<CR>",
            },
        },
    },
    {
        name = "lsp",
        dir = vim.fn.stdpath("config"),
        lazy = false,
        config = function()
            vim.diagnostic.config({
                virtual_text = false,
                signs = false,
                underline = true,
                update_in_insert = false,
                severity_sort = false,
            })
            require("lsp").set_lspconfigs()
        end,
        keys = {
            {
                "<Leader>=",
                function()
                    vim.lsp.buf.format({ timeout = 1000 })
                end,
            },
            {
                "<Leader>dq",
                function()
                    vim.diagnostic.setqflist()
                    vim.cmd.copen()
                end,
            },
            {
                "<Leader>dQ",
                function()
                    vim.diagnostic.setloclist()
                    vim.cmd.lopen()
                end,
            },
        },
    },
    {
        name = "shelly",
        dir = vim.fn.stdpath("config"),
        lazy = false,
        opts = {
            split = {
                direction = "horizontal",
                size = 14,
                position = "bottom",
            },
            start_in_insert = false,
            focus = false,
        },
        keys = {
            {
                "<Leader>a",
                ":S ",
                mode = "n",
            },
            {
                "<Leader>A",
                function()
                    require("shelly").toggle()
                end,
                mode = "n",
            },
            {
                "<C-q>",
                "<C-\\><C-n>",
                mode = "t",
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
}
