local M = {}

M.setup = function()
  local nvim_treesitter = require "nvim-treesitter.configs"
  nvim_treesitter.setup {
    autotag = {
      enable = true,
      filetypes = { "html", "htmldjango", "xml"}
    },
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


