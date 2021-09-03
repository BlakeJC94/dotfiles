------------------------
--  General Settings  --
------------------------

UNDO_DIR = os.getenv "HOME" .. "/.vim/undo/"

local M = {}

M.load_options = function()
   local opt = vim.opt

   local default_options = {  -- create table of options
      clipboard = "unnamedplus", -- allows neovim to access the system clipboard
      cmdheight = 2, -- more space in the neovim command line for displaying messages
      fileencoding = "utf-8",  -- use utf-8 file encoding
      foldmethod = "manual",  -- code folding, set to "expr" for treesitter based folding
      foldexpr = "", -- set to "nvim_treesitter#foldexpr()" for treesitter based folding 
      hlsearch = true,  -- highlight all matches on previous search pattern
      ignorecase = true,  -- ignore case when searching, see also: smartcase
      smartcase = true, -- case sensitive search if at least one letter is uppercase
      mouse = "a",  -- enable mouse for nvim
      showmode = false,  -- don't show which mode we are in
      -- pumheight = 10,  -- popup menu height
      splitbelow = true,  -- force all horizontal splits to go below current window
      splitright = true, -- force all vertical splits to go to the right of current window
      termguicolors = true,  -- set term gui colors 
      title = true,  -- set the title of window to the value of the titlestring
      expandtab = true,  -- convert tabs to spaces
      shiftwidth = 2,  -- the number of spaces inserted for each indentation
      tabstop = 2,  -- insert 2 spaces for a tab
      cursorline = true,  -- highlight the current line
      number = true,  -- set numbered lines
      relativenumber = true,  -- set relative numbered lines
      numberwidth = 4,  -- set number column width
      signcolumn = "yes",  -- always show the sign column, otherwise it would shift text each time
      spell = false,  -- 
      spelllang = "en",  -- 
      scrolloff = 8,  -- Minimal number of lines to keep above and below the cursor
      sidescrolloff = 8,  -- same as above, except for left and right, if nowrap is set
      -- timeoutlen = 100, -- time to wait for a mapped sequence to complete (in milliseconds)
      undodir = UNDO_DIR, -- set an undo directory
      undofile = true, -- enable persistent undo
      updatetime = 300, -- faster completion
      wrap = false,  -- display lines as one long line
      autoread = true,  -- Detect changes in files if they are edited outside of nvim
      wildmenu = true,  -- Shows possible matches when using tab completion
      showtabline = 2,  -- always show tabs
      guifont = "JetBrains\\ Mono\\ Regular\\ Nerd\\ Font\\ Complete:h11",
      hidden = true,  -- any buffer can be hidden (keeping its changes)
   }

   -- assign all options in default_options
   for k, v in pairs(default_options) do
      vim.opt[k] = v
   end

  -- completion global settings
  vim.o.completeopt = "menuone,noselect"

  -- good defaults for sessions
  vim.o.sessionoptions="blank,buffers,curdir,folds,help,options,tabpages,winsize,resize,winpos,terminal"


  -- colorscheme
  vim.g.tokyonight_style = "storm"
  vim.g.tokyonight_terminal_colors = true
  vim.g.tokyonight_italic_keywords = true
  vim.g.tokyonight_transparent = false
  vim.g.tokyonight_sidebars = { "terminal", "packer", "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches", "dap-repl" }
  vim.cmd[[colorscheme tokyonight]]

end

----------------------------
--  General Autocommands  --
----------------------------

M.load_commands = function()
   local cmd = vim.cmd

   cmd "au BufWritePost plugins.lua source <afile> | PackerCompile"  -- automatically run :PackerCompile whenever plugins.lua is updated
   -- cmd "au BufEnter * silent! lcd %:p:h"
end

return M
