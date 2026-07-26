vim.opt_local.formatoptions:remove("tc")
vim.opt_local.wrap = true
vim.opt_local.conceallevel = 1
vim.opt_local.foldlevel = 1

vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4

-- Treesitter folds
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
