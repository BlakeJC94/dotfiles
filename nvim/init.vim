"$CONF/nvim/init.vim
"
" vim-plug {{{
  call plug#begin('~/.local/share/nvim/site/plugged')

  " Plug 'vim-test/vim-test'

  Plug 'stefandtw/quickfix-reflector.vim' "modifiable quickfix list

  Plug 'tpope/vim-dispatch' "tpope, his holiness

  Plug 'itchyny/lightline.vim' "Status bar

  Plug 'ctrlpvim/ctrlp.vim' "fuzzy finder

  Plug 'jiangmiao/auto-pairs' "prevent 'missing parenthesis and brackets' typos

  Plug 'sirver/UltiSnips' "Special Snippets for nvim

  Plug 'dense-analysis/ale' "async linting

  Plug 'mengelbrecht/lightline-bufferline' "Lightline-like bufferline

  Plug 'tpope/vim-commentary' "Easy commenting

  Plug 'ap/vim-css-color' "Convert hex values to color

  Plug 'airblade/vim-gitgutter' "git diff in side column

  Plug 'deoplete-plugins/deoplete-jedi' " python autocomplete

  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } "autocomplete

  Plug 'machakann/vim-highlightedyank' "Highlight when I yank

  Plug 'xolox/vim-misc' "Required stuff for vim-session

  Plug 'xolox/vim-session' "Vim session persistence 'easy button'

  Plug 'ghifarit53/daycula-vim' , {'branch' : 'main'} "colorscheme

  Plug 'tpope/vim-fugitive' "git integration

  Plug 'sheerun/vim-polyglot' "lots of syntax highlighting

  Plug 'mhinz/vim-startify' "vim start screen

  Plug 'ryanoasis/vim-devicons' "icons; MUST BE LOADED LAST TO WORK WITH OTHER 
    " PLUGINS

  call plug#end()
" }}}

" General {{{
  "
  "Force leader character
  let mapleader = '\'

  " Detect changes in files if they are edited outside of nvim
  set autoread

  "Enable recursive search downward with :find
  set path+=**

  "Shows possible matches when using tab completion
  set wildmenu

  set showtabline=2

  "Use desktop clipboard for yank
  set clipboard=unnamedplus

  "Relative line Numbers
  set nu
  set rnu

  "Syntax highlighting
  syntax on

  "UTF-8 encoding
  set encoding=utf-8

  "Cursor highlighting
  set cursorline

  "Enable code folding
  "set foldmethod=indent
  "set foldlevel=99

  set termguicolors

  let g:daycula_transparent_background=1
  "hi! Normal ctermbg=NONE guibg=NONE

  "Set colorscheme
  colorscheme daycula

  " any buffer can be hidden (keeping its changes) without first writing the 
    " buffer to a file
  set hidden


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

  "set colorcolumn=80
  hi ColorColumn ctermbg=lightgrey guibg=#24285e

  "Change to current directory upon opening file, anytime
  "set autochdir
  autocmd BufEnter * silent! lcd %:p:h

  "Open quickix list after :make and :grep
  " augroup grep_quickfix
  "   autocmd!
  "   autocmd QuickFixCmdPost [^l]* :copen
  "   autocmd QuickFixCmdPost l*    :copen
  " augroup END

" }}}

" Deoplete {{{

  let g:deoplete#sources#jedi#show_docstring = 1

  let g:python3_host_prog = $HOME . '/.virtualenvs/pynvim/bin/python3'

  let g:deoplete#enable_at_startup = 1

  call deoplete#custom#option('sources', {
		\ 'python': ['jedi', 'ultisnips'],
		\ })

  " Make sure that deoplete starts
  " Fixes issue when opening a file or (files) from stdin
  autocmd VimEnter * call deoplete#enable()

  set completeopt-=preview

" }}}

" Netrw {{{ 

  "Use tree listing style
  let g:netrw_liststyle = 3
  
  "Open files in vertical split
  let g:netrw_browse_split = 2

  "Size of netrw
  let g:netrw_winsize = 25

  "Use wildignore list as netrw hide list
  let g:netrw_list_hide = &wildignore

  "Keep the current directory and the browsing directory synced. 
  "This helps you avoid the move files error.
  let g:netrw_keepdir = 0

  autocmd FileType netrw setl bufhidden=wipe
" }}} 

" ALE {{{
"
  let pynvim_path = $HOME . '/.virtualenvs/pynvim/bin/'

  let g:ale_python_auto_pipenv = 1

  let g:ale_python_flake8_executable = pynvim_path . 'flake8'

  let g:ale_python_flake8_change_directory = 1 

  let g:ale_python_isort_executable = pynvim_path . 'isort'

  let g:ale_python_black_executable = pynvim_path . "black"

  let g:ale_python_black_change_directory = 1

  let g:ale_python_pydocstyle_executable = pynvim_path . 'pydocstyle'

  let g:ale_mypy_ignore_invalid_syntax = 1

  let g:ale_fix_on_save = 1

" }}}

" Lightline Settings {{{
  "Component functions need to go after 'active' block
  let g:lightline = {
    \ 'colorscheme': 'daycula',
    \ 'active': {
    \	'left': [ [ 'mode', 'paste' ],
    \     [ 'gitbranch' ],
    \     [ 'readonly', 'filename', 'modified', 'venv' ] ]
    \ },
    \ 'component_function': {
    \   'gitbranch': 'helpers#lightline#gitBranch',
    \   'venv': 'helpers#lightline#venv',
    \   'filetype': 'MyFiletype',
    \   'fileformat': 'MyFileformat'
    \ },
    \ 'tabline': {
    \   'left': [ ['buffers'] ],
    \   'right': [ [''] ]
    \ },
    \ 'component_expand': {
    \   'buffers': 'lightline#bufferline#buffers'
    \ },
    \ 'component_type': {
    \   'buffers': 'tabsel'
    \ },
    \ }

    "	  'gitbranch': 'helpers#lightline#gitBranch',
  "********************Makes icons work with lightline**************************
  function! MyFiletype()
    return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . 
          \ WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
  endfunction

  function! MyFileformat()
    return winwidth(0) > 70 ? (&fileformat . ' ' . 
          \ WebDevIconsGetFileFormatSymbol()) : ''
  endfunction
  "*****************************************************************************

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

" }}}

" CtrlP {{{

  let g:ctrlp_working_path_mode = 'ra'

  let g:ctrlp_root_markers = ['pyproject.toml', 'poetry.lock']

  let g:ctrlp_by_filename = 1

  let g:ctrlp_regexp = 1

  let g:ctrlp_show_hidden = 1

  set wildignore+=*/tmp/*,*.so,*.swp,*.zip,**__pycache__**,*/.venv/*,*/.git/*

  let g:ctrlp_prompt_mappings = {
    \ 'PrtSelectMove("j")':   ['<c-n>', '<down>'],
    \ 'PrtSelectMove("k")':   ['<c-p>', '<up>'],
    \ 'PrtHistory(-1)':       [''],
    \ 'PrtHistory(1)':        [''],
    \ }

" }}} 

" Startify {{{
  let g:startify_lists = [
          \ { 'type': 'files',     'header': ['   Recent Files']  },
          \ { 'type': 'sessions',  'header': ['   Sessions']      },
          \ { 'type': 'bookmarks', 'header': ['   Bookmarks']     },
          \ ]
          "\ { 'type': 'commands',  'header': ['   Commands']      },
          " \ { 'type': 'dir',     'header': ['   '. getcwd()]  },
          "\ { 'type': function('s:nerdtreeBookmarks'), 'header': ['   NERDTree Bookmarks']},
          "\ { 'type': 'commands',  'header': ['   Commands']      },


  "Startify session dir
  let g:startify_session_dir = '.vim/sessions/'

  "Startify bookmarks
  let g:startify_bookmarks= [
              \ {'py': '$HOME/code/python/'},
              \ {'pr': '$CONF/bash/.profile'},
              \ {'br': '$CONF/bash/.bashrc'},
              \ {'ba': '$CONF/bash/.bash_aliases'},
              \ {'v': '$CONF/nvim/init.vim'},
              \ {'a': '$CONF/alacritty/alacritty.yml'},
              \ {'t': '$CONF/tmux/tmux.conf'},
              \ ]

  "Startify commands
  "let g:startify_commands = [
  "        \   { 'up': [ 'Update Plugins', ':PlugUpdate' ] },
  "        \   { 'ug': [ 'Upgrade Plugin Manager', ':PlugUpgrade' ] },
  "        \   { 'uc': [ 'Clean Up Plugins', ':PlugClean' ] },
  "        \ ]

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
                  " \ |   NERDTree
                  \ |   wincmd w
                  \ | endif

" }}}

" vim-session {{{
  "Location of session scripts
  "let g:session_directory =

  "Name of default session
  "let g:session_default_name='std'

  "Open default session without prompt
  let g:session_autoload='no'

  let g:session_autosave='no'


" }}}

" UltiSnips {{{
  let g:UltiSnipsExpandTrigger='<tab>'

  " shortcut to go to next position
  " let g:UltiSnipsJumpForwardTrigger='<c-j>'

  " shortcut to go to previous position
  " let g:UltiSnipsJumpBackwardTrigger='<c-k>'

  let g:UltiSnipsEditSplit='horizontal'

  let g:ultisnips_python_style='sphinx'

" }}}

" Remaps {{{
  "Window movements
  nnoremap <C-J> <C-W><C-J>
  nnoremap <C-K> <C-W><C-K>
  nnoremap <C-L> <C-W><C-L>
  nnoremap <C-H> <C-W><C-H>

  nnoremap <M-h> <C-o>
  nnoremap <M-l> <C-i>
  
  ""Vert diff
  nnoremap <leader>diff :vert diffsplit 
 
  "File refresh
  nnoremap <F5> :so %<CR>

  "Folding with spacebar
  nnoremap <space> za

  " Local Refactor
  " (https://stackoverflow.com/questions/14942104/vim-using-contents-of-a-variable-inside-search-and-replace-expression)
  nnoremap \rf :execute "normal! viw\"ry"<CR> :%s/<C-R><C-R>=@r<CR>//g<Left><Left>
  " nnoremap \rf :execute ':%s/' . expand('<cword>') . '//g'
  
  ""Resize buffer to 80
  nnoremap \wr :vertical resize 88<CR>

  "Change splits
  nnoremap \| <C-W><C-V>
  nnoremap _ <C-W><C-S>

  "Easy quit
  nnoremap <C-q> <C-W><C-Q>

  "open init.vim in a vsplit
  nnoremap <leader>ev :vsplit $MYVIMRC<CR>

  "open startify menu
  nnoremap <leader>st :Startify<CR>

  nnoremap <leader>deo :call deoplete#toggle()<CR>

  nnoremap <leader>t :Lexplore<CR>

  nnoremap <leader>gg :call helpers#ggrep#GgrepHelper()<CR>
" }}}

" tmux shortcuts {{{
  "/******************/
  "/* tmux shortcuts */
  "/******************/

  function Run_cd()
    let select = helpers#tmux_panes#check_panes()
    exe ' !' . select . 'tmux send-keys -t 2 "clear; cd "' . expand('%:p:h') . 
          \ ' C-m'
  endfunction

  nnoremap <leader>cd :silent call Run_cd() <CR>

" }}}
