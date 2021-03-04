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

"Override default pythonDot color
highlight link pythonDot Red

"Insert breakpoint
nnoremap <leader>b :execute "normal! Obreakpoint()\e"<cr>

"Use .venv/bin/python with deoplete-jedi when using venv
if ale#python#FindVirtualenv(bufnr('%')) !=# ''
  let g:deoplete#sources#jedi#python_path = ale#python#FindVirtualenv(bufnr('%'))
        \ . '/bin/python'

  "Map F8 to 'poetry run python <filename>' when using venv
  nnoremap <buffer> <F8> :w<CR> :silent call Run_python_poetry() <CR>
else
  "Map F8 to regular python when not using venv
  nnoremap <buffer> <F8> :w<CR> :silent call Run_python() <CR>

endif  

"Only use these fixers
let b:ale_fixers = ['black', 'isort']

"Only use these linters
let b:ale_linters = ['flake8', 'mypy', 'pydocstyle']


function! Run_python_poetry()
  let pane = helpers#tmux_panes#check_panes()
  exe ' !' . pane . 'tmux send-keys -t 2 "clear; poetry run python "' . 
        \ expand('%') . ' C-m'
endfunction

function! Run_python()
  let pane = helpers#tmux_panes#check_panes()
  exe ' !' . pane . 'tmux send-keys -t 2 "clear; python "' . 
        \ expand('%') . ' C-m'
endfunction

function! Run_python_tests()
  let select = helpers#tmux_panes#check_panes()
  exe ' !' . select . 'tmux send-keys -t 2 "clear; poetry run pytest -v"'
        \ . ' C-m'
endfunction

nnoremap <buffer> <F7> :w<CR> :silent call Run_python_tests() <CR>


