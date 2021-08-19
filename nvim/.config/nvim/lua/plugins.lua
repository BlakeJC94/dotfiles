return require('packer').startup(function(use)

  use "wbthomason/packer.nvim" -- Packer can manage itself

  use "neovim/nvim-lspconfig"  -- A collection of common configurations for Neovim's built-in language server client

  use "folke/tokyonight.nvim"  -- Colorscheme

  use "tjdevries/nlua.nvim"

  -- LSP UI
  use {
    "glepnir/lspsaga.nvim",
    -- config = function()
    --   local saga = require 'lspsaga'
    --   saga.init_lsp_saga()
    -- end
  }

  -- change cwd to the project's root using LSP
  use {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup{
        patterns = {"init.lua", ".git"},
        ignore_lsp = {"sumneko_lua"}
      }
    end
  }

  -- search
  use {
    "nvim-telescope/telescope.nvim",
    requires = {'nvim-lua/popup.nvim', 'nvim-lua/plenary.nvim'},
    config = function()
      require("config.telescope").setup()
    end,
  }

  -- completion
  --use {
  --  "hrsh7th/nvim-compe",
  --  event = "InsertEnter",
  --  config = function()
  --    require("config.compe").setup()
  --  end,
 -- }

  -- autopairs
  use {
   "windwp/nvim-autopairs",
   event = "InsertEnter",
   -- after = "nvim-compe",
   config = function()
     require "config.autopairs"
   end,
 }

  -- Treesitter
  use {
   "nvim-treesitter/nvim-treesitter",
    branch = "0.5-compat",
    run = ":TSUpdate",
    config = function()
      require("config.treesitter").setup()
    end,
  }

  -- NvimTree
  use {
   "kyazdani42/nvim-tree.lua",
   -- event = "BufWinOpen",
   -- cmd = "NvimTreeToggle",
   -- commit = "fd7f60e242205ea9efc9649101c81a07d5f458bb",
   config = function()
     require("config.nvimtree").setup()
   end,
 }

  -- Git diff signs
  use {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("config.gitsigns").setup()
    end,
    event = "BufRead",
  }

  -- Comments
  use {
    "terrortylor/nvim-comment",
    event = "BufRead",
    config = function()
      require("nvim_comment").setup()
    end,
  }

  -- nvim-bufferline
  use {
    'akinsho/nvim-bufferline.lua',
    config = function()
      require("config.bufferline").setup()
    end,
    event = "BufWinEnter",
  }


  -- Debugging
  --use {
  --  "mfussenegger/nvim-dap",
  --  -- event = "BufWinEnter",
  --  config = function()
  --    require("config.dap").setup()
  --  end,
 -- }

   -- Dashboard
  use {
    "glepnir/dashboard-nvim",
    event = "BufWinEnter",
    config = function()
      require("config.dashboard").setup()
    end,
  }

  -- Terminal
  use {
    "akinsho/nvim-toggleterm.lua",
    event = "BufWinEnter",
    config = function()
      require("config.terminal").setup()
    end,
  }

  -- Turn Hex into color
  use {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup()
    end
 }
  
  -- Devicons
  use {
    "kyazdani42/nvim-web-devicons",
    config = function()
      require("config.nvim_web_devicons").setup()
    end
  }

  -- Status line
  use {
    "hoob3rt/lualine.nvim",
    config = function()
      require("lualine").setup({ options = {theme = 'tokyonight'} })
    end
  }

  -- Rest client
  use {
    'NTBBloodbath/rest.nvim',
    requires = { 'nvim-lua/plenary.nvim' },
    ft = 'http',
    config = function()
        require('rest-nvim').setup()
    end
  }

end)
