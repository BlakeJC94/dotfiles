local M = {}

M.setup = function()
  nvim_treesitter = require "nvim-treesitter.configs"
  nvim_treesitter.setup {
    ensure_installed = { "python", 
                         "bash",
                         "css",
                         "comment",
                         "dockerfile",
                         "go",
                         "html",
                         "javascript",
                         "json",
                         "lua",
                         "regex",
                         "toml",
                         "yaml",
                         -- "yang",
                       },
    highlight = {
      enable = true 
    },
    -- indent = {
    --   enable = true
    -- },
  }
end

return M


