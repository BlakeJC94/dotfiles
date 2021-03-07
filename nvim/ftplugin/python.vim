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

let test#strategy = "dispatch"

compiler pyunit  "Fix quickfix list for python tracebacks
setl makeprg=python\ %  "Default makeprg for python

"Override default pythonDot color
highlight link pythonDot Red

"Insert breakpoint
nnoremap <leader>b :execute "normal! Obreakpoint()\e"<cr>

"Use .venv/bin/python with deoplete-jedi when using venv
if ale#python#FindVirtualenv(bufnr('%')) !=# ''
  let g:deoplete#sources#jedi#python_path = ale#python#FindVirtualenv(bufnr('%'))
        \ . '/bin/python'

  "Set makeprg to use poetry when a venv is available
  setl makeprg=poetry\ run\ python\

  "Map F8 to use vim-dispatch :Make
  nnoremap <buffer> <F8> :w<CR> :Make %<CR>

  let test#project_root = ale#python#FindProjectRoot(bufnr('%'))
  nnoremap <buffer> <F7> :w<CR> :exe 'Start -dir=root poetry run pytest -v '

endif  

"Only use these fixers
let b:ale_fixers = ['black', 'isort']

"Only use these linters
let b:ale_linters = ['flake8', 'mypy', 'pydocstyle', 'jedils']

"Map F8 to use vim-dispatch :Make
nnoremap <buffer> <F8> :w<CR> :Make python\ %<CR>

" function! Run_python_poetry()
"   let b:make = "poetry run python %"
" endfunction

" function! Run_python()
"   let b:make = "python %"
" endfunction

nnoremap <buffer> <F7> :w<CR> :TestSuite <CR>


