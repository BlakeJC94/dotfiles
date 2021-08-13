local utils = require "utils"

vim.g.mapleader = "\\"

local opts = {
  nnoremap = { noremap = true, silent = true },
  inoremap = { noremap = true, silent = true },
  vnoremap = { noremap = true, silent = true },
  xnoremap = { noremap = true, silent = true },
  tnoremap = { noremap = true, silent = true },
}

local default_keys = {
  insert_mode = { },

  normal_mode = {
    -- Better window movement
    { "<C-h>", "<C-w>h" },
    { "<C-j>", "<C-w>j" },
    { "<C-k>", "<C-w>k" },
    { "<C-l>", "<C-w>l" },

    -- Resize with arrows
    { "<C-Up>", ":resize -2<CR>" },
    { "<C-Down>", ":resize +2<CR>" },
    { "<C-Left>", ":vertical resize -2<CR>" },
    { "<C-Right>", ":vertical resize +2<CR>" },

    { "<F5>", ":so %<CR>" },  -- source file
    { "<space>", "za" },  -- easy folding

    { "|", "<C-W><C-V>" },  -- easy vsplit
    { "_", "<C-W><C-S>" },  -- easy hsplit

    { "<C-q>", "<C-W><C-Q>" },  -- easy quit

    -- Telescope
    { "<C-p>", "<cmd>lua require('telescope.builtin').find_files()<cr>" },
    { "<leader>gg", "<cmd>lua require('telescope.builtin').live_grep()<cr>" },
    { "<leader>r", "<cmd>lua require('telescope.builtin').oldfiles()<cr>"},

    -- NvimTree
    { "<leader>t", ":NvimTreeToggle<CR>" },
    -- { "<leader>t", "<cmd>lua require('config.nvimtree').toggle_tree()<cr>" },
    { "<leader>ff", ":NvimTreeFindFile<CR>"},
    -- { "<leader>ff", "<cmd>lua require('config.nvimtree').find_file()<cr>" },

    -- nvim-bufferline
    { '<leader><leader>', ':BufferLineCycleNext<CR>' },
    { '<leader>bd', ':BufferLinePickClose<CR>' },

    -- See all ToggleTerm terminals
    { "<tab><tab>", ":ToggleTermOpenAll<CR>" },  
  },

  term_mode = {
    -- Terminal window navigation
    { "<C-h>", "<C-\\><C-N><C-w>h" },
    { "<C-j>", "<C-\\><C-N><C-w>j" },
    { "<C-k>", "<C-\\><C-N><C-w>k" },
    { "<C-l>", "<C-\\><C-N><C-w>l" },

    -- Terminal resize
    { "<C-w>K", "<C-\\><C-N>z70<CR>i" },
    { "<C-w>J", "<C-\\><C-N>z20<CR>i" },

    -- ToggleTerm
    { "<tab><tab>", "<C-\\><C-n>:ToggleTermCloseAll<CR>" },
    { "<leader>2", "<C-\\><C-n>:2ToggleTerm<CR>" },
    { "<leader>3", "<C-\\><C-n>:3ToggleTerm<CR>" },
    { "<leader>4", "<C-\\><C-n>:4ToggleTerm<CR>" },
  },

  visual_mode = {
    -- Better indenting\
    { "<", "<gv" },
    { ">", ">gv" },

  },

  visual_block_mode = {
    -- Move selected line / block of text in visual mode
    { "K", ":move '<-2<CR>gv-gv" },
    { "J", ":move '>+1<CR>gv-gv" },

  },
}

utils.add_keymap_normal_mode(opts.nnoremap, default_keys["normal_mode"])
utils.add_keymap_insert_mode(opts.inoremap, default_keys["insert_mode"])
utils.add_keymap_visual_mode(opts.vnoremap, default_keys["visual_mode"])
utils.add_keymap_visual_block_mode(opts.xnoremap, default_keys["visual_block_mode"])
utils.add_keymap_term_mode(opts.tnoremap , default_keys["term_mode"])
