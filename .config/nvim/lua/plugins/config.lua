return {
    dir = vim.fn.stdpath("config") .. "/lua/config",
    lazy = false,
    opts = {},
    keys = {

        ------------------------------------------------------------
        -- Command-line history
        --
        -- <Up>/<Down> filter history by the text already typed.
        -- Prefix matching, like a shell.
        ------------------------------------------------------------
        {
            "<Up>",
            function()
                return _G.config.history_search(-1)
            end,
            mode = "c",
            expr = true,
        },
        {
            "<Down>",
            function()
                return _G.config.history_search(1)
            end,
            mode = "c",
            expr = true,
        },

        ------------------------------------------------------------
        -- Motion tweaks
        ------------------------------------------------------------

        -- j/k: step through display lines when no count is given.
        -- Large counts (over 5) set a jumplist mark first.
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

        -- { / }: do not pollute the jumplist.
        { "{", ":<C-u>keepjumps norm! {<CR>" },
        { "}", ":<C-u>keepjumps norm! }<CR>" },

        -- n / N: open folds under the cursor when jumping
        -- between search matches.
        { "n", "nzv" },
        { "N", "Nzv" },

        ------------------------------------------------------------
        -- Text editing
        ------------------------------------------------------------

        -- x / X / s: cut to the black hole register.
        -- Keeps the clipboard untouched.
        { "x", '"_x' },
        { "X", '"_X' },
        { "s", '"_s' },

        -- q / Q: swap to avoid accidental macro recording.
        -- q -> format motion (gw), Q -> record macro.
        { "q", "gw" },
        { "Q", "q" },

        ------------------------------------------------------------
        -- Visual mode
        ------------------------------------------------------------

        -- < / > / =: reselect the block after indenting.
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

        -- p / P: paste over without losing the register.
        -- The replaced text is sent to the black hole register.
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

        ------------------------------------------------------------
        -- g-prefixed maps
        ------------------------------------------------------------

        -- gV: reselect the last pasted or changed text.
        -- Like gv, but for the paste block.
        { "gV", "`[v`]" },

        -- gF: open the file under the cursor.
        -- Creates the file if it does not exist.
        { "gF", ":e <c-r><c-f><CR>" },

        -- gcp / gcP: paste, then comment the pasted text.
        { "gcp", "p`[v`]gc", remap = true },
        { "gcP", "p`[v`]gc", remap = true },

        ------------------------------------------------------------
        -- Spell check (<C-s> prefix)
        --
        -- A small spell menu for insert and normal mode.
        -- All fixes are undoable.
        ------------------------------------------------------------

        -- <C-s><C-s>: fix the misspelled word before the cursor.
        -- Picks the first suggestion.
        {
            "<C-s><C-s>",
            "<C-g>u<Esc>[s1z=`]i<C-g>u",
            mode = "i",
            remap = false,
        },

        -- <C-s><C-x>: show the suggestion list for the word
        -- before the cursor.
        {
            "<C-s><C-x>",
            "<C-r>u<C-r>z=",
            mode = "i",
            remap = true,
        },

        -- <C-s><C-a>: add the word before the cursor to the
        -- spell file.
        {
            "<C-s><C-a>",
            "<Esc>[szg`]i",
            mode = "i",
            remap = false,
        },

        -- <C-s><C-d>: remove the word before the cursor from the
        -- spell file.
        {
            "<C-s><C-d>",
            "<C-r>zug",
            mode = "i",
            remap = false,
        },

        -- Same spell actions, normal mode variants:
        --   <C-s><C-s> fix previous misspelled word
        --   <C-s><C-x> suggestion list
        --   <C-s><C-a> add word to spell file
        --   <C-s><C-d> remove word from spell file
        {
            "<C-s><C-s>",
            "i<C-g>u<Esc>[s1z=`]i<C-g>u<Esc>",
            remap = false,
        },
        {
            "<C-s><C-x>",
            "uz=",
            remap = true,
        },
        {
            "<C-s><C-a>",
            "[szg`]",
            remap = false,
        },
        {
            "<C-s><C-d>",
            "zug",
            remap = false,
        },

        ------------------------------------------------------------
        -- UI and display
        ------------------------------------------------------------

        -- <C-l>: clear search highlighting, recompute folds,
        -- then redraw the screen.
        {
            "<C-l>",
            ":noh<CR>zx<C-l>",
            silent = true,
        },

        -- <F1> in insert mode: disabled.
        -- Stops accidental help windows.
        {
            "<F1>",
            "",
            mode = "i",
        },

        -- Arrow keys: repurposed as fold and fold-adjacent
        -- navigation.
        --   <Up>    move to previous fold
        --   <Down>  move to next fold
        --   <Left>  close fold under cursor
        --   <Right> open fold under cursor
        { "<Up>", "zk" },
        { "<Down>", "zj" },
        { "<Left>", "zc" },
        { "<Right>", "zo" },

        ------------------------------------------------------------
        -- Function keys: option toggles
        --
        -- Each toggle echoes the new value.
        ------------------------------------------------------------

        -- <F1>: toggle line numbers.
        {
            "<F1>",
            ":setl number!<CR>:setl number?<CR>",
            silent = false,
        },

        -- <F2>: toggle relative line numbers.
        {
            "<F2>",
            ":setl relativenumber!<CR>:setl relativenumber?<CR>",
            silent = false,
        },

        -- <F3>: toggle line wrapping.
        {
            "<F3>",
            ":setl wrap!<CR>:setl wrap?<CR>",
            silent = false,
        },

        -- <F4>: toggle spell checking.
        {
            "<F4>",
            ":setl spell!<CR>:setl spell?<CR>",
            silent = false,
        },

        -- <F5>: reload files changed outside Neovim.
        {
            "<F5>",
            ":checktime<CR>",
            silent = false,
        },

        -- <F6>: equalize all window sizes.
        {
            "<F6>",
            ":wincmd =<CR>",
            silent = false,
        },

        ------------------------------------------------------------
        -- Window resizing
        --
        -- Horizontal moves are wider than vertical ones,
        -- since columns are narrower than rows.
        ------------------------------------------------------------
        { "<C-Left>", ":wincmd 8<<CR>" },
        { "<C-Up>", ":wincmd 4+<CR>" },
        { "<C-Down>", ":wincmd 4-<CR>" },
        { "<C-Right>", ":wincmd 8><CR>" },

        ------------------------------------------------------------
        -- Tabs (<Leader>z prefix)
        ------------------------------------------------------------
        { "<Leader>zc", ":tabedit %<CR>" }, -- open current file in new tab
        { "<Leader>zn", ":tabnext<CR>" },   -- next tab
        { "<Leader>zp", ":tabprev<CR>" },   -- previous tab
        { "<Leader>zN", ":+tabmove<CR>" },  -- move tab right
        { "<Leader>zP", ":-tabmove<CR>" },  -- move tab left
        { "<Leader>zq", ":tabclose<CR>" },  -- close tab

        ------------------------------------------------------------
        -- Leader maps
        ------------------------------------------------------------

        -- <Leader>e: select the entire buffer.
        { "<Leader>e", "ggVG" },

        -- <Leader><Tab>: jump to the alternate (last) file.
        { "<Leader><Tab>", "<C-^>" },

        -- <Leader>O: close every buffer except the current one.
        { "<Leader>O", ":%bd|e#|bd# <CR>" },

        -- <Leader>q / <Leader>Q: toggle quickfix and local lists.
        {
            "<Leader>q",
            ":ToggleQuickfixList<CR>",
            silent = true,
        },
        {
            "<Leader>Q",
            ":ToggleLocalList<CR>",
            silent = true,
        },

        -- <Leader>;: open the Neovim config.
        { "<Leader>;", "<cmd>edit ~/.config/nvim/init.lua | lcd ~/.config/nvim/ <CR>" },

        -- <Leader>:: open the Lazy plugin manager.
        { "<Leader>:", "<cmd>Lazy<CR>" },

        -- <Leader>.: set the window-local directory
        -- to the current file's folder.
        { "<Leader>.", "<cmd>lcd %:p:h | echo 'Changed local dir to ' . getcwd()<CR>" },

        -- <Leader>,: set the global working directory
        -- to the current file's folder.
        { "<Leader>,", "<cmd>cd %:p:h | echo 'Changed dir to ' . getcwd()<CR>" },

        -- <Leader>/: set the working directory
        -- to the git repository root.
        { "<Leader>/", "<cmd>cd `git rev-parse --show-toplevel` | echo 'Changed dir to ' . getcwd()<CR>" },

        ------------------------------------------------------------
        -- LSP
        ------------------------------------------------------------

        -- <Leader>=: format the buffer with conform.nvim.
        {
            "<Leader>=",
            function()
                require("conform").format()
            end,
            silent = true,
        },

        -- <Leader>dq: fill the quickfix list with diagnostics.
        {
            "<Leader>dq",
            ":LspDiagnosticQuickfixList<CR>",
            silent = true,
        },

        -- <Leader>dQ: fill the local (window) list with diagnostics.
        {
            "<Leader>dQ",
            ":LspDiagnosticLocalList<CR>",
            silent = true,
        },
    },
}