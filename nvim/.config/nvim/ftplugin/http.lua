vim.api.nvim_buf_set_keymap(0, "n", "<F8>", ":lua require('rest-nvim').run()<CR>", { noremap = true, silent = true })

vim.api.nvim_buf_set_keymap(0, "n", "<F7>", ":lua require('rest-nvim').run(true)<CR>", { noremap = true, silent = true })
