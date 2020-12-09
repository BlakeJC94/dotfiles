"$CONF/nvim/init.vim
"
" vim-plug {{{
  call plug#begin('~/.local/share/nvim/site/plugged')

  Plug 'benmills/vimux' "easily interact with tmux

  Plug 'itchyny/lightline.vim' "Status bar

  Plug 'scrooloose/nerdtree' "Fancy file explorer

  Plug 'tiagofumo/vim-nerdtree-syntax-highlight' "Pretty colors for NERDTree files/glyphs

  "Plug 'tmhedberg/SimpylFold' "Code folding for Python
  "
  Plug 'sirver/UltiSnips' "Special Snippets for nvim

  " Plug 'honza/vim-snippets' "A lot of snippets
  
  Plug 'dense-analysis/ale' "async linting

  Plug 'mengelbrecht/lightline-bufferline' "Lightline-like bufferline

  Plug 'tpope/vim-commentary' "Easy commenting

  Plug 'ap/vim-css-color' "Convert hex values to color

  Plug 'airblade/vim-gitgutter' "git diff in side column

  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } "autocomplete

  Plug 'deoplete-plugins/deoplete-jedi' " python autocomplete

  "Plug 'racer-rust/vim-racer' "rust auto

  Plug 'sbdchd/neoformat' "Code formatter

  Plug 'machakann/vim-highlightedyank' "Highlight when I yank

  "Plug 'momota/cisco.vim'

  "Plug 'mtdl9/vim-log-highlighting'

  Plug 'xolox/vim-misc' "Required stuff for vim-session

  Plug 'xolox/vim-session' "Vim session persistence 'easy button'

  Plug 'ghifarit53/daycula-vim' , {'branch' : 'main'} "colorscheme

  Plug 'tpope/vim-fugitive' "git integration

  Plug 'sheerun/vim-polyglot' "lots of syntax highlighting

  Plug 'mhinz/vim-startify' "vim start screen

  Plug 'ryanoasis/vim-devicons' "icons; MUST BE LOADED LAST TO WORK WITH OTHER PLUGINS

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

  " any buffer can be hidden (keeping its changes) without first writing the buffer to a file
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

" }}}

" Vimux {{{

  let g:VimuxHeight = '40'

" }}}

" Deoplete {{{

  let g:python3_host_prog = $HOME . '/.virtualenvs/pynvim/bin/python3'

  let g:deoplete#enable_at_startup = 1
  
  set completeopt-=preview

" }}}

" ALE {{{

  let pynvim_path = $HOME . '/.virtualenvs/pynvim/bin/'

  let g:ale_python_mypy_executable = pynvim_path . 'mypy'

  let g:ale_python_mypy_options = '--ignore-missing-imports'

  let g:ale_python_flake8_executable = pynvim_path . 'flake8'

  let g:ale_python_autopep8_executable = pynvim_path . 'autopep8'

  let g:ale_python_isort_executable = pynvim_path . 'isort'

  let g:ale_python_black_executable = pynvim_path . 'black'

  let g:ale_python_pydocstyle_executable = pynvim_path . 'pydocstyle'

  let g:ale_fix_on_save = 1

" }}}

" Lightline Settings {{{
  "Component functions need to go after 'active' block
  let g:lightline = {
    \ 'colorscheme': 'daycula',
    \ 'active': {
    \	'left': [ [ 'mode', 'paste' ],
    \     [ 'gitbranch' ],
    \     [ 'readonly', 'filename', 'modified' ] ]
    \ },
    \ 'component_function': {
    \   'gitbranch': 'helpers#lightline#gitBranch',
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

" }}}

" NERDTree {{{

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
  "function! s:nerdtreeBookmarks()
  "    let bookmarks = systemlist("cut -d' ' -f 2 ~/.NERDTreeBookmarks")
  "    let bookmarks = bookmarks[0:-2] " Slices an empty last line
  "    return map(bookmarks, \"{'line': v:val, 'path': v:val}")
  "endfunction

" }}}

" Startify {{{
  let g:startify_lists = [
          \ { 'type': 'files',     'header': ['   Recent Files']  },
          \ { 'type': 'sessions',  'header': ['   Sessions']      },
          \ { 'type': 'bookmarks', 'header': ['   Bookmarks']     },
          \ ]
          "\ { 'type': 'commands',  'header': ['   Commands']      },
          "\ { 'type': 'dir',     'header': ['   '. getcwd()]  },
          "\ { 'type': function('s:nerdtreeBookmarks'), 'header': ['   NERDTree Bookmarks']},
          "\ { 'type': 'commands',  'header': ['   Commands']      },


  "Startify session dir
  let g:startify_session_dir = '.vim/sessions/'

  "Startify bookmarks
  let g:startify_bookmarks= [
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


  "get rid of [  ] around icons in NerdTree
  if exists("g:loaded_webdevicons")
    call webdevicons#refresh()
  endif
" }}}

" UltiSnips {{{
  let g:UltiSnipsExpandTrigger='<tab>'

  " shortcut to go to next position
  let g:UltiSnipsJumpForwardTrigger='<c-n>'

  " shortcut to go to previous position
  let g:UltiSnipsJumpBackwardTrigger='<c-p>'

  let g:UltiSnipsEditSplit='horizontal'

  let g:ultisnips_python_style='sphinx'

" }}}

" Remaps {{{
  "Window movements
  nnoremap <C-J> <C-W><C-J>
  nnoremap <C-K> <C-W><C-K>
  nnoremap <C-L> <C-W><C-L>
  nnoremap <C-H> <C-W><C-H>

  "File refresh
  nnoremap <F5> :so %<CR>

  "Folding with spacebar
  nnoremap <space> za

  "Local Refactor
  "(https://stackoverflow.com/questions/14942104/vim-using-contents-of-a-variable-inside-search-and-replace-expression)
  nnoremap \rf :execute "normal! viw\"ry"<CR> :%s/<C-R><C-R>=@r<CR>//g<Left><Left>

  "Resize buffer to 80
  nnoremap \80 :vertical resize 80<CR>

  "Change splits
  nnoremap \| <C-W><C-V>
  nnoremap _ <C-W><C-S>

  "Easy quit
  nnoremap <C-q> <C-W><C-Q>

  "Startify
  nnoremap <leader>s :Startify<CR>

  "Uppercase a word from normal mode
  nnoremap \u <C-v>bU

  "open init.vim in a vsplit
  nnoremap <leader>ev :vsplit $MYVIMRC<CR>

  "deoplete selection remap
  inoremap <C-j> <C-n>
  inoremap <C-k> <C-p>

  "deoplete preview window close
  nnoremap \pq :pclose<CR>

" }}}

" tmux shortcuts {{{
  "/******************/
  "/* tmux shortcuts */
  "/******************/

  function! Run_cd()
    let select = helpers#tmux_panes#check_panes()
    exe ' !' . select . 'tmux send-keys -t 2 "clear; cd "' . expand('%:p:h') . ' C-m'
  endfunction

  nnoremap <leader>cd :silent call Run_cd() <CR>

  " nnoremap <leader>cd :silent !tmux select-pane -t 2;tmux send-keys C-m 'cd ' %:p:h C-m<CR>
" }}}

