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
  auto_open = 1,
  auto_close = 1,
  quit_on_open = 0,
  follow = 1,
  hide_dotfiles = 0,
  git_hl = 1,
  root_folder_modifier = ":t",
  tab_open = 0,
  group_empty = 1,
  -- respect_buf_cwd = 1,
  -- allow_resize = 1,
  lsp_diagnostics = 1,
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

  g.nvim_tree_bindings = {
    { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
    { key = "h", cb = tree_cb "close_node" },
    { key = "v", cb = tree_cb "vsplit" },
  }
end

-- -- allocate space for bufferline when toggling nvimtree
-- M.toggle_tree = function()
--   local view_status_ok, view = pcall(require, "nvim-tree.view")
--   if not view_status_ok then
--     return
--   end
--   if view.win_open() then
--     require("nvim-tree").close()
--     if package.loaded["bufferline.state"] then
--       require("bufferline.state").set_offset(0)
--     end
--   else
--     if package.loaded["bufferline.state"] and nvimtree_config.side == "left" then
--       -- require'bufferline.state'.set_offset(lvim.builtin.nvimtree.width + 1, 'File Explorer')
--       require("bufferline.state").set_offset(nvimtree_config.width + 1, "File Explorer")
--     end
--     require("nvim-tree").toggle()
--   end
-- end
-- 
-- -- allocate space for bufferline when finding a file in nvimtree
-- M.find_file = function()
--   local view_status_ok, view = pcall(require, "nvim-tree.view")
--   if not view_status_ok then
--     return
--   end
--   if package.loaded["bufferline.state"] and nvimtree_config.side == "left" then
--     -- require'bufferline.state'.set_offset(lvim.builtin.nvimtree.width + 1, 'File Explorer')
--     require("bufferline.state").set_offset(nvimtree_config.width + 1, "File Explorer")
--   end
--   require("nvim-tree").find_file(true)
-- end
-- 
-- 
-- 
return M
