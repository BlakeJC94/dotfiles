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
    { "<C-Up>", ":resize +20<CR>" },
    { "<C-Down>", ":resize -20<CR>" },
    { "<C-Left>", ":vertical resize -20<CR>" },
    { "<C-Right>", ":vertical resize +20<CR>" },

    { "<F5>", ":so %<CR>" },  -- source file
    { "<space>", "za" },  -- easy folding

    { "|", "<C-W><C-V>" },  -- easy vsplit
    { "_", "<C-W><C-S>" },  -- easy hsplit

    { "<C-q>", "<C-W><C-Q>" },  -- easy quit

    -- Telescope
    { "<C-p>", "<cmd>lua require('telescope.builtin').find_files(require('config.telescope').no_preview())<cr>" },
    { "<leader>gg", "<cmd>lua require('telescope.builtin').live_grep(require('config.telescope').no_preview())<cr>" },
    { "<M-o>", "<cmd>lua require('telescope.builtin').oldfiles(require('config.telescope').no_preview())<cr>"},

    -- NvimTree
    { "<leader>t", ":NvimTreeToggle<CR>" },
    -- { "<leader>t", "<cmd>lua require('config.nvimtree').toggle_tree()<cr>" },
    { "<leader>ff", ":NvimTreeFindFile<CR>"},
    -- { "<leader>ff", "<cmd>lua require('config.nvimtree').find_file()<cr>" },

    -- nvim-bufferline
    { '<M-n>', ':BufferLineCycleNext<CR>' },
    { '<M-p>', ':BufferLineCyclePrev<CR>' },
    { '<leader>bd', ':BufferLinePickClose<CR>' },
    { '<M-1>', '<cmd>BufferLineGoToBuffer 1<CR>'},
    { '<M-2>', '<cmd>BufferLineGoToBuffer 2<CR>'},
    { '<M-3>', '<cmd>BufferLineGoToBuffer 3<CR>'},
    { '<M-4>', '<cmd>BufferLineGoToBuffer 4<CR>'},
    { '<M-5>', '<cmd>BufferLineGoToBuffer 5<CR>'},
    { '<M-6>', '<cmd>BufferLineGoToBuffer 6<CR>'},
    { '<M-7>', '<cmd>BufferLineGoToBuffer 7<CR>'},
    { '<M-8>', '<cmd>BufferLineGoToBuffer 8<CR>'},
    { '<M-9>', '<cmd>BufferLineGoToBuffer 9<CR>'},

    --nvim-dap-ui
    { '<leader>d', '<cmd>lua require("dapui").toggle()<CR>' },
  },

  term_mode = {
    -- Terminal window navigation
    { "<C-h>", "<C-\\><C-N><C-w>h" },
    { "<C-j>", "<C-\\><C-N><C-w>j" },
    { "<C-k>", "<C-\\><C-N><C-w>k" },
    { "<C-l>", "<C-\\><C-N><C-w>l" },

    -- { "<Esc>", "<C-\\><C-N>" },

    -- Resize terminal with z80 and z20 in normal mode

    -- Create a split with [3,4,5,6,...] Ctrl + \
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
