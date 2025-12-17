local config = require("BlakeJC94")

config.set_mappings(
    {
        -- Better jumplist for large line steps (and step through visual lines with j/k)
        { "j", [[(v:count > 5 ? 'm`' . v:count : 'g') . 'j']], expr = true },
        { "k", [[(v:count > 5 ? 'm`' . v:count : 'g') . 'k']], expr = true },
        -- gV: Visually select last pasted block (like gv)
        { "gV", "`[v`]" },
        -- gF: create new file at filename over cursor
        { "gF", "<cmd>e <c-r><c-f><CR>" },
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
        { "<", "<gv", mode = "v" },
        { ">", ">gv", mode = "v" },
        { "=", "=gv", mode = "v" },
        -- Swap p and P to stop losing register contents by pasting over
        { "p", '"_dp', mode = "v" },
        { "P", '"_dP', mode = "v" },
        -- C-s : Quickly guess correct spelling errors (undoable)
        { "<C-s>", "<C-g>u<Esc>[s1z=`]i<C-g>u", mode = "i", remap = false },
        { "<C-s>", "i<C-g>u<Esc>[s1z=`]", remap = false },
        -- C-x : Execute
        { "<C-x><C-x>", "<C-g>u<Esc>:.!sh<CR>`]<C-g>u", mode = "i", remap = false },
        { "<C-x>", "<C-g>u:.!sh<CR>`]", remap = false },
        { "<C-x>", "<C-g>u:.!sh<CR>`]", mode = "x", remap = false },
        -- Stop accidentally opening help in insert mode
        { "<F1>", "", mode = "i" },
        -- Terminal mode
        { "<C-z>", "<C-\\><C-n>", mode="t" },
        -- Use unused arrow keys
        { "<Left>", "[", remap = true },
        { "<Right>", "]", remap = true },
        { "<Up>", "[", remap = true },
        { "<Down>", "]", remap = true },
        -- Fkey maps
        { "<F1>", ":setl relativenumber!<CR>:setl relativenumber?<CR>", silent = false },
        { "<F2>", ":setl number!<CR>:setl number?<CR>", silent = false },
        { "<F3>", ":setl wrap!<CR>:setl wrap?<CR>", silent = false },
        { "<F4>", ":setl spell!<CR>:setl spell?<CR>", silent = false },
        { "<F5>", ":checktime<CR>", silent = false },
        { "<F6>", ":wincmd =<CR>", silent = false },
        -- Resize split maps
        { "<C-Left>", ":wincmd 8<<CR>" },
        { "<C-Up>", ":wincmd 4+<CR>" },
        { "<C-Down>", ":wincmd 4-<CR>" },
        { "<C-Right>", ":wincmd 8><CR>" },
        -- Vim Tab controls
        { "<Leader>t", ":tabedit %<CR>" },
        { "<Leader>n", ":tabnext<CR>" },
        { "<Leader>p", ":tabnext<CR>" },
        { "<Leader>N", ":+tabmove<CR>" },
        { "<Leader>P", ":-tabmove<CR>" },
        -- Align selection to table
        { "<Leader>s", ":!column -to' '<CR>", mode="x" },
        -- Select all
        { "<Leader>e", "ggVG" },
        -- Change kwarg to field
        { '<Leader>i', ':s/^\\(\\s*\\)\\(\\S.\\+\\)\\s*=\\(.*\\)$/\\1"\\2": \\3<CR>' },
        { '<Leader>o', ':s/^\\(\\s*\\)["\']\\(\\S.\\+\\)["\']\\s*:\\s*\\(.*\\)$/\\1\\2=\\3<CR>' },
        -- Leader maps
        { "<Leader><Tab>", "<C-^>" }, -- Last file
        { "<Leader>O", ":%bd|e#|bd# <CR>" },  -- Clear buffers
        { "<Leader>q", config.functions.toggle_quickfix_list },
        { "<Leader>Q", config.functions.toggle_local_list },
        { "<Leader>;", "<cmd>edit $MYVIMRC | lcd %:p:h<CR>" },
        { "<Leader>:", "<cmd>source $MYVIMRC<CR>" },
        { "<Leader>.", "<cmd>lcd %:p:h | echo 'Changed local dir to ' . getcwd()<CR>" },
        { "<Leader>,", "<cmd>cd %:p:h | echo 'Changed dir to ' . getcwd()<CR>" },
        { "<Leader>/", "<cmd>cd `git rev-parse --show-toplevel` \\| echo 'Changed dir to project root: ' . getcwd()<CR>" },
    }
)

local undo_mappings = {}
for _, mark in pairs({ ".", ",", "!", "?", "(", ")", "[", "]", "{", "}", "<", ">", '"', "'" }) do
    undo_mappings[#undo_mappings + 1] = { mark, mark .. "<C-g>u", mode = "i" }
end
config.set_mappings(undo_mappings)

local arrow_mappings = {}
for _, mod in pairs({ "S-", "A-" }) do
    for _, dir in pairs({ "Left", "Down", "Up", "Right" }) do
        arrow_mappings[#arrow_mappings + 1] = { "<" .. mod .. dir .. ">", "" }
    end
end
config.set_mappings(arrow_mappings)
