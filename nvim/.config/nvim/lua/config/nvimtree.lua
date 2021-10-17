local M = {}

nvimtree_config = {
  side = "left",
  width = 30,
  show_icons = {
    git = 1,
    folders = 1,
    files = 1,
    folder_arrows = 1,
  },
  ignore = { "__pycache__", ".git", "node_modules", ".cache" },
  quit_on_open = 0,
  hide_dotfiles = 0,
  git_hl = 1,
  root_folder_modifier = ":t",
  respect_buf_cwd = 1,
  group_empty = 1,
  -- respect_buf_cwd = 1,
  -- allow_resize = 1,
  auto_ignore_ft = { "startify", "dashboard" },
  icons = {
    default = "",
    symlink = "",
    git = {
      unstaged = "",
      staged = "S",
      unmerged = "",
      renamed = "➜",
      deleted = "",
      untracked = "U",
      ignored = "◌",
    },
    folder = {
      default = "",
      open = "",
      empty = "",
      empty_open = "",
      symlink = "",
    },
},
}

M.setup = function()
  local g = vim.g

  for opt, val in pairs(nvimtree_config) do
    g["nvim_tree_" .. opt] = val
  end

  local nvim_tree_config = require "nvim-tree.config"
  local tree_cb = nvim_tree_config.nvim_tree_callback
--
--   g.nvim_tree_bindings = {
--     { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
--     { key = "h", cb = tree_cb "close_node" },
--     { key = "v", cb = tree_cb "vsplit" },
--   }
  require'nvim-tree'.setup {
    disable_netrw       = true,
    -- open the tree when running this setup function
    open_on_setup       = false,
    -- will not open on setup if the filetype is in this list
    ignore_ft_on_setup  = {},
    -- closes neovim automatically when the tree is the last **WINDOW** in the view
    auto_close          = true,
    -- opens the tree when changing/opening a new tab if the tree wasn't previously opened
    open_on_tab         = false,
    -- hijack the cursor in the tree to put it at the start of the filename
    hijack_cursor       = false,
    -- updates the root directory of the tree on `DirChanged` (when your run `:cd` usually)
    update_cwd          = true,

    diagnostics = {
      enable = true
    },
    -- show lsp diagnostics in the signcolumn
    -- lsp_diagnostics     = true,
    -- update the focused file on `BufEnter`, un-collapses the folders recursively until it finds the file
    update_focused_file = {
      -- enables the feature
      enable      = true,
      -- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory
      -- only relevant when `update_focused_file.enable` is true
      update_cwd  = true,
      -- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory
      -- only relevant when `update_focused_file.update_cwd` is true and `update_focused_file.enable` is true
      ignore_list = {}
    },
    -- configuration options for the system open command (`s` in the tree by default)
    system_open = {
      -- the command to run this, leaving nil should work in most cases
      cmd  = nil,
      -- the command arguments as a list
      args = {}
    },

    view = {
      -- width of the window, can be either a number (columns) or a string in `%`
      width = 30,
      -- side of the tree, can be one of 'left' | 'right' | 'top' | 'bottom'
      side = 'left',
      -- if true the tree will resize itself after opening a file
      auto_resize = false,
      mappings = {
        -- custom only false will merge the list with the default mappings
        -- if true, it will only use your list to set the mappings
        custom_only = false,
        -- list of mappings to set on the tree manually
        list = {
          { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
          { key = "h", cb = tree_cb "close_node" },
          { key = "v", cb = tree_cb "vsplit" },
        }
      }
    }
  }
end

return M
