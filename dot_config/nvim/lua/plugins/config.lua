return {
    dir = vim.fn.stdpath("config"),
    name = "BlakeJC94",
    lazy = false,
    opts = {},
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
        -- gcp/gcP: paste register and comment oout
        { "gcp", "p`[v`]gc", remap=true },
        { "gcP", "p`[v`]gc", remap=true },
        -- Make {/} don't change the jump list
        { "{", ":<C-u>keepjumps norm! {<CR>" },
        { "}", ":<C-u>keepjumps norm! }<CR>" },
        -- Prevent x and s from overriding what's in the clipboard
        { "x", '"_x' },
        { "X", '"_X' },
        { "s", '"_s' },
        -- Open folds when flicking through search matches
        { "n", "nzv" },
        { "N", "Nzv" },
        -- Remap q and Q to stop polluting registers accidentally!
        { "q", "gw" },
        { "Q", "q" },
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
        -- <Leader>-x : Execute
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
        { "<C-Left>", ":wincmd 8<<CR>" },
        { "<C-Up>", ":wincmd 4+<CR>" },
        { "<C-Down>", ":wincmd 4-<CR>" },
        { "<C-Right>", ":wincmd 8><CR>" },
        -- Vim Tab controls
        { "<Leader>zc", ":tabedit %<CR>" },
        { "<Leader>zn", ":tabnext<CR>" },
        { "<Leader>zp", ":tabnext<CR>" },
        { "<Leader>zN", ":+tabmove<CR>" },
        { "<Leader>zP", ":-tabmove<CR>" },
        -- Select all
        { "<Leader>e", "ggVG" },
        -- Leader maps
        { "<Leader><Tab>", "<C-^>" }, -- Last file
        { "<Leader>O", ":%bd|e#|bd# <CR>" }, -- Clear buffers
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
        { "<Leader>;", "<cmd>edit ~/.config/nvim/init.lua | lcd ~/.config/nvim/ <CR>" },
        { "<Leader>.", "<cmd>lcd %:p:h | echo 'Changed local dir to ' . getcwd()<CR>" },
        { "<Leader>,", "<cmd>cd %:p:h | echo 'Changed dir to ' . getcwd()<CR>" },
        { "<Leader>/", "<cmd>cd `git rev-parse --show-toplevel` | echo 'Changed dir to ' . getcwd()<CR>" },
        -- LSP Maps
        {
            "<Leader>=",
            ":LspFormat<CR>",
            silent = true,
        },
        {
            "<Leader>dq",
            ":LspDiagnosticQuickfixList<CR>",
            silent = true,
        },
        {
            "<Leader>dQ",
            ":LspDiagnosticLocalList<CR>",
            silent = true,
        },
    },
}
