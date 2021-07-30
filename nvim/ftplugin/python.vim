"/*******************/
"/* Python Settings */
"/*******************/
"
setl tabstop=4
setl softtabstop=4
setl shiftwidth=4
setl textwidth=88
setl expandtab
setl autoindent
setl fileformat=unix
setl formatoptions+=t
setl cc=+1
setl nofoldenable

"Only use these fixers
let b:ale_fixers = ['black', 'isort']

"Only use these linters
let b:ale_linters = ['flake8', 'mypy']

"Insert breakpoint
nnoremap <leader>b :execute "normal! Obreakpoint()\e"<cr>

let b:project_root = ale#python#FindProjectRoot(bufnr('%'))

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                             vim-test for Python                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use :Start to begin 'poetry run pytest'
function! StartStrategy(cmd)
  exe 'Start -wait=always ' . a:cmd
endfunction

" Use :Start! to begin a background iteration of 'poetry run pytest'
function! BgStartStrategy(cmd)
  exe 'Start! -wait=always ' . a:cmd
endfunction

"Define custom strategies
let g:test#custom_strategies = {
      \ 'Start': function('StartStrategy'),
      \ 'Start!': function('BgStartStrategy'),
      \}

"Define strategies per command
let g:test#strategy = {
  \ 'nearest': 'Start',
  \ 'file': 'Start',
  \ 'suite': 'Start!',
  \}

let test#python#pytest#executable = 'poetry run pytest'


let test#project_root = b:project_root
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                   Handle venvs and define dispatch.vim stuff             "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if ale#python#FindVirtualenv(bufnr('%')) != ''
  let b:venv_available = 1
else
  let b:venv_available = 0
endif

let b:venv_path = ale#python#FindVirtualenv(bufnr('%')) . '/bin/python'

" compiler pyunit  "Fix quickfix list for python tracebacks
" setl makeprg=python\ % "Default makeprg for python

"Use .venv/bin/python with deoplete-jedi when using venv
if b:venv_available ==# 1
  let g:deoplete#sources#jedi#python_path = b:venv_path

  "Set makeprg to use poetry when a venv is available
  " setl makeprg=poetry\ run\ python\ %

  "Map F8 to use vim-dispatch :Make
  nnoremap <buffer> <F8> :w<CR> :call VimuxRunCommand("clear; poetry run python " . bufname("%"))<CR>

  "Run all tests for a project
  nnoremap <buffer> <F7> :w<CR> :call helpers#test_helpers#RunAllTests('pytest') <CR>

endif  

"Map F8 to use vim-dispatch :Make
" nnoremap <buffer> <F8> :w<CR> :Make <CR>
