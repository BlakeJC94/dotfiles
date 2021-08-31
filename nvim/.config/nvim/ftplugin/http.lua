vim.api.nvim_buf_set_keymap(0, "n", "<Enter>", ":lua require('rest-nvim').run()<CR>", { noremap = true, silent = true })

vim.api.nvim_buf_set_keymap(0, "n", "<F9>", ":lua require('rest-nvim').run(true)<CR>", { noremap = true, silent = true })

vim.api.nvim_buf_set_keymap(0, "n", "<F5>", ":e %<CR>", { noremap = true, silent = true })
