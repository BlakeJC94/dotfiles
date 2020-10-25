"~/.config/nvim/init.vim

call plug#begin('~/.local/share/nvim/site/plugged')

"Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
"Plug 'junegunn/fzf.vim'
"Plug 'sonph/onehalf', {'rtp': 'vim'}
Plug 'itchyny/lightline.vim'
Plug 'terryma/vim-multiple-cursors'
Plug 'scrooloose/nerdtree'
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'tmhedberg/SimpylFold'
Plug 'mengelbrecht/lightline-bufferline'
"Plug 'dense-analysis/ale'
"Plug 'airblade/vim-gitgutter
"Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"Plug 'jiangmiao/auto-pairs'
"Plug 'scrooloose/nerdcommenter'
"Plug 'sbdchd/neoformat'
"Plug 'davidhalter/jedi-vim'
"Plug 'machakann/vim-highlightedyank'
"Plug 'justincampbell/vim-eighties'
"Plug 'momota/cisco.vim'
"Plug 'mtdl9/vim-log-highlighting'
"vim-rooter
Plug 'xolox/vim-misc'
Plug 'xolox/vim-session'
Plug 'tpope/vim-fugitive'
"Plug 'chriskempson/base16-vim'
"Plug 'nicknisi/vim-base16-lightline'
Plug 'ghifarit53/daycula-vim' , {'branch' : 'main'}
Plug 'sheerun/vim-polyglot'
Plug 'mhinz/vim-startify'
Plug 'ryanoasis/vim-devicons' "MUST BE LOADED LAST TO WORK WITH OTHER PLUGINS

call plug#end()

"/********************/
"/* General Settings */
"/********************/
set showtabline=2

"Use desktop clipboard for yank
set clipboard=unnamed

"Numbers
set nu

"Syntax highlighting
syntax on

"fonts
"set guifont=Ubuntu\ Nerd\ Font\ Complete\ 14

"UTF-8 encoding
set encoding=utf-8

"Cursor highlighting
set cursorline

"Enable code folding
set foldmethod=indent
set foldlevel=99

set termguicolors

let g:daycula_transparent_background=1
"hi! Normal ctermbg=NONE guibg=NONE

"Set colorscheme
colorscheme daycula




set t_Co=256 " Explicitly tell vim that the terminal supports 256 colors


if &term =~ '256color' " disable background color erase
    set t_ut=
endif

" enable 24 bit color support if supported
if (has("termguicolors"))
    if (!(has("nvim")))
        let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
        let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    endif
    set termguicolors
endif

" highlight conflicts
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

"Insert space characters whenever tab is pressed
set expandtab

"Controls the number of space characters to insert with tab
set tabstop=2

"Number of space characters inserted for indentation
set shiftwidth=2

set wrap

if has ('mouse')
	set mouse=a
endif

"Change to current directory upon opening file, anytime
"set autochdir

autocmd BufEnter * silent! lcd %:p:h

"/*******************/
"/* Python Settings */
"/*******************/
  
au BufNewFile,BufRead *.py
	\set tabstop=4 |
	\set softtabstop=4 |
	\set shiftwidth=4 |
	\set textwidth=79 |
	\set expandtab |
	\set autoindent |
	\set fileformat=unix |
	\set formatoptions+=t |

au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match Whitespace /\s\+$/

"/*******************/
"/* Plugin Settings */
"/*******************/

let g:lightline = {
	\ 'colorscheme': 'daycula',
	\ 'active': {
	\	'left': [ [ 'mode', 'paste' ],
  \			[ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
	\ },
  \ 'tabline': {
  \   'left': [ ['buffers'] ],
  \   'right': [[ ]]
  \ },
  \ 'component_expand': {
  \   'buffers': 'lightline#bufferline#buffers'
  \ },
  \ 'component_type': {
  \   'buffers': 'tabsel'
	\ },
	\ 'component_funtion': {
	\	  'gitbranch': 'FugitiveHead'
	\ },
  \ 'component_function': {
  \   'filetype': 'MyFiletype',
  \   'fileformat': 'MyFileformat',
  \ }
	\ }

"********************Makes icons work with lightline**********************************
function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction

function! MyFileformat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction
"*************************************************************************************

"bufferline
let g:lightline#bufferline#show_number=2
let g:lightline#bufferline#enable_devicons=1
let g:lightline#bufferline#enable_nerdfont=1
let g:lightline#bufferline#clickable=1
let g:lightline#bufferline#smart_path=1
let g:lightline.component_raw = {'buffers': 1}

nmap <Leader>1 <Plug>lightline#bufferline#go(1)
nmap <Leader>2 <Plug>lightline#bufferline#go(2)
nmap <Leader>3 <Plug>lightline#bufferline#go(3)
nmap <Leader>4 <Plug>lightline#bufferline#go(4)
nmap <Leader>5 <Plug>lightline#bufferline#go(5)
nmap <Leader>6 <Plug>lightline#bufferline#go(6)
nmap <Leader>7 <Plug>lightline#bufferline#go(7)
nmap <Leader>8 <Plug>lightline#bufferline#go(8)
nmap <Leader>9 <Plug>lightline#bufferline#go(9)

"NERDTreeToggle shortcut
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'


"NERDTree Alternate bindings
nmap <leader>t :NERDTreeToggle<CR>
let g:NERDTreeMapOpenVSplit = "v"
let g:NERDTreeMapOpenSplit = "s"
nmap <leader>f :NERDTreeFind<cr>

"let g:NERDTreeLimitedSyntax = 1 *Use in case icons slow down navigation
let g:NERDTreeShowBookmarks = 1



"Close NERDTree if it is last thing open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif


" Read ~/.NERDTreeBookmarks file and takes its second column
function! s:nerdtreeBookmarks()
    let bookmarks = systemlist("cut -d' ' -f 2 ~/.NERDTreeBookmarks")
    let bookmarks = bookmarks[0:-2] " Slices an empty last line
    return map(bookmarks, "{'line': v:val, 'path': v:val}")
endfunction


let g:startify_lists = [
        \ { 'type': 'commands',  'header': ['   Commands']      },
        \ { 'type': 'files',     'header': ['   Recent Files']  },
        \ { 'type': 'sessions',  'header': ['   Sessions']      },
        \ { 'type': function('s:nerdtreeBookmarks'), 'header': ['   NERDTree Bookmarks']},
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']     },
        \ ]


"Startify session dir
let g:startify_session_dir='~/.config/nvim/sessions'

"Startify bookmarks
let g:startify_bookmarks= [ 
            \ {'v': '~/.config/nvim/init.vim'}, 
            \ {'a': '~/.config/alacritty/alacritty.yml'}, 
            \ {'t': '~/.config/tmux/tmux.conf'}, 
            \ ]

"Startify commands
let g:startify_commands = [
        \   { 'up': [ 'Update Plugins', ':PlugUpdate' ] },
        \   { 'ug': [ 'Upgrade Plugin Manager', ':PlugUpgrade' ] },
        \   { 'uc': [ 'Clean Up Plugins', ':PlugClean' ] },
        \ ]

let g:startify_custom_header = [
            \ '                                           ',
            \ '      _   _                 _              ',
            \ '     | \ | |               (_)             ',
            \ '     |  \| | ___  _____   ___ _ __ ___     ',
            \ '     | . ` |/ _ \/ _ \ \ / / | ''_ ` _ \    ',
            \ '     | |\  |  __/ (_) \ V /| | | | | | |   ',
            \ '     |_| \_|\___|\___/ \_/ |_|_| |_| |_|   ',
            \ '                                           ',
            \ ] 

"When opening a file or bookmark, change to its directory.
let g:startify_change_to_dir = 1

"number of files to list
let g:startify_files_number = 10


"get both NERDTree and Startify working at startup
autocmd VimEnter *
                \   if !argc()
                \ |   Startify
                \ |   NERDTree
                \ |   wincmd w
                \ | endif


"Location of session scripts
let g:session_directory='~/.config/nvim/sessions'

"Name of default session
"let g:session_default_name='std'

"Open default session without prompt
let g:session_autoload='no'

"let g:session_autosave='no'



"/**********/
"/* Remaps */
"/**********/

"Window movements
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"File refresh
nnoremap <F5> :so %<CR>

"Folding with spacebar
nnoremap <space> za

"Change splits
nnoremap \| <C-W><C-V>
nnoremap _ <C-W><C-S>

"Easy quit
nnoremap <C-q> <C-W><C-Q>


"get rid of [  ] around icons in NerdTree
if exists("g:loaded_webdevicons")
  call webdevicons#refresh()
endif
