-- q to quit Fugitive
vim.keymap.set('n', 'q', '<cmd>q<CR>', { buffer = true, silent = true })

-- p/P to pull/push (Press <CR> to confirm)
-- Note: We map to the command string so it waits for the user to press Enter
vim.keymap.set('n', 'p', ':Git pull', { buffer = true, silent = true })
vim.keymap.set('n', 'P', ':Git push', { buffer = true, silent = true })

-- Fugitive buffers as scratch buffers
vim.opt_local.bufhidden = 'delete'
vim.opt_local.buftype = 'nofile'
vim.opt_local.modifiable = false
