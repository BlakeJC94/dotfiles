local M = {}

M.setup = function()
  local actions = require('telescope.actions')
  telescope = require "telescope"
  -- telescope.setup(telescope_config)
  telescope.setup {
    defaults = {
      prompt_prefix = "   ",
      selection_caret = " ",
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
      },
      color_devicons = true,
      file_ignore_patterns = {"Applications", 
                              "Calibre% Library", 
                              "Music", 
                              "Pictures", 
                              "Tresors", 
                              "Videos", 
                              "VirtualBox_VMs", 
                              "vmware", 
                              ".local",
                              "__pycache__",
                              ".*%.pdf"},
      mappings = {
        i = {
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<esc>"] = actions.close
      },
    },

  },
}
end

return M
