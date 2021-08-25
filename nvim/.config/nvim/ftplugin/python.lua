--/*******************/
--/* Python Settings */
--/*******************/

-- vim.opt_local.tabstop = 4
-- vim.opt_local.softtabstop = 4
-- vim.opt_local.shiftwidth = 4
-- vim.opt_local.textwidth = 88

vim.opt_local.expandtab = true

-- vim.opt_local.cc = vim.opt_local.cc + 1  -- set column line one more than textwidth

-- File runner
vim.api.nvim_buf_set_keymap(0, 'n', '<F8>', '<cmd>lua require("utils").run_python()<CR>', { noremap = true })
