" Bootstrap plug.vim
let dir = (has('nvim') ? '~/.config/nvim' : '~/.vim')
if empty(glob(dir . '/autoload/plug.vim'))
  " Download plug.vim
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  " Source plug.vim so that the pluig#begin/end calls work below
  source ~/.vim/autoload/plug.vim
  " Call PlugInstall once everything is up
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Load plugins
call plug#begin(expand(dir . '/plugged'))

"" ENHANCEMENTS
Plug 'https://github.com/tpope/vim-sensible'    " Sane defaults
Plug 'https://github.com/tpope/vim-rsi'         " Readline shortcuts for insert mode
Plug 'https://github.com/tpope/vim-eunuch'      " Unix commands
Plug 'https://github.com/tpope/vim-repeat'      " Better dot-repeat action
Plug 'https://github.com/tpope/vim-surround'    " Surrounds (`cs<ch><ch>`, `ys<motion><char>`) <>
Plug 'https://github.com/tpope/vim-commentary'  " Toggle comments (`gc<motion>`) <>
Plug 'https://github.com/tpope/vim-fugitive'    " Fugitive: The Ultimate `:Git` plugin (`<leader>c`) <>
Plug 'https://github.com/tpope/vim-rhubarb'     " GitHub integration for `:GBrowse` (`<leader>b`)

"" ACTIONS
" Sub-word text object (`iv`, `av`)
Plug 'https://github.com/kana/vim-textobj-user'
Plug 'https://github.com/Julian/vim-textobj-variable-segment'

"" INTERFACE
" Fzf <3 Vim
Plug 'https://github.com/junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'https://github.com/junegunn/fzf.vim'

"" STYLE
" Colorscheme
Plug 'https://github.com/gruvbox-community/gruvbox'

call plug#end()
