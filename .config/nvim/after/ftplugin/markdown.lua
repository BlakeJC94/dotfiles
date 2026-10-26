vim.opt_local.formatoptions:remove("tc")
vim.opt_local.wrap = true
vim.opt_local.conceallevel = 1
vim.opt_local.foldlevel = 1

-- Treat backslash commands as words so they can expand on a delimiter.
vim.opt_local.iskeyword:append("\\")
vim.cmd([[inoreabbrev <buffer> <expr> \log '* ' . strftime('%H%M')[:2] . '0']])
vim.cmd([[inoreabbrev <buffer> \todo * [ ] **TODO**]])
vim.cmd([[inoreabbrev <buffer> \comment * **COMMENT**]])
vim.cmd([[inoreabbrev <buffer> \idea * **IDEA**:]])
vim.cmd([[inoreabbrev <buffer> \question * **QUESTION**]])
vim.cmd([[inoreabbrev <buffer> \answer * **ANSWER**]])
vim.cmd([[inoreabbrev <buffer> \action * **ACTION**]])
vim.cmd([[inoreabbrev <buffer> \note * **NOTE**]])

vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.shiftwidth = 4

-- Treesitter folds
vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
