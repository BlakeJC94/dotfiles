--/*******************/
--/* Python Settings */
--/*******************/

-- vim.opt_local.tabstop = 4
-- vim.opt_local.softtabstop = 4
-- vim.opt_local.shiftwidth = 4
-- vim.opt_local.textwidth = 88

vim.opt_local.expandtab = true

-- ifmain block
vim.cmd[[ :iabbrev ifmain if __name__ == "__main__":<CR> ]]

-- File runner
vim.api.nvim_buf_set_keymap(0, 'n', '<F8>', '<cmd>lua require("utils").run_python()<CR>', { noremap = true })

-- Test runner
-- vim.api.nvim_buf_set_keymap(0, 'n', '<F4>', '<cmd>lua require("utils").run_python_tests()<CR>', { noremap = true })

-- Easy skip test
vim.api.nvim_buf_set_keymap(0, 'n', '<leader>st', 'O@unittest.skip("skipping")<ESC>', { noremap = true })
