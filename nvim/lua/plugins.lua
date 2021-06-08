 -- This file can be loaded by calling `lua require('plugins')` from your init.vim
 

return require('packer').startup(function()

   use 'wbthomason/packer.nvim'
   use 'nvim-lua/popup.nvim'
   use "nvim-lua/plenary.nvim"
   use {
     'nvim-telescope/telescope.nvim',
     requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
   }
   use {'Shados/neuron.nvim', branch = 'autocmd-neuron-dir-fixes'}

 end, {
  display = {
    open_fn = require('packer.util').float,
  }
})
