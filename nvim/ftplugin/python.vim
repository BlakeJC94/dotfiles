"/*******************/
"/* Python Settings */
"/*******************/
"
setl tabstop=4 
setl softtabstop=4 
setl shiftwidth=4 
setl textwidth=79 
setl expandtab 
setl autoindent 
setl fileformat=unix 
setl formatoptions+=t 
setl cc=+1

"Python-specific ALE settings
let g:ale_python_autopep8_executable = $HOME . "/.virtualenvs/pynvim/bin/autopep8"

let g:ale_python_flake8_executable = $HOME . "/.virtualenvs/pynvim/bin/flake8"

let g:ale_python_isort_executable = $HOME . "/.virtualenvs/pynvim/bin/isort"

let g:ale_python_mypy_executable = $HOME . "/.virtualenvs/pynvim/bin/mypy"

let b:ale_fixers = ['autopep8', 'isort', 'add_blank_lines_for_python_control_statements', 
      \ 'remove_trailing_lines', 'trim_whitespace']


"TODO: make these functions not echo the text
function! Run_python()
  let select = helpers#tmux_panes#check_panes()
  exe ' !' . select . 'tmux send-keys -t 2 C-m "python "' . expand('%')
endfunction

function! Run_python_tests()
  let select = helpers#tmux_panes#check_panes()
  exe ' !' . select . 'tmux send-keys -t 2 C-m "py.test -v"'
endfunction

nnoremap <F8> :w<CR> :silent call Run_python() <CR>

nnoremap <F7> :w<CR> :silent call Run_python_tests() <CR>


