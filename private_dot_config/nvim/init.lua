vim.g.mapleader = " "

 vim.fn.stdpath("config")

dofile(vim.fn.stdpath("config") .. "/options.lua")
dofile(vim.fn.stdpath("config") .. "/plugins.lua")
dofile(vim.fn.stdpath("config") .. "/mappings.lua")
