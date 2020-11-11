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

match Whitespace /\s\+$/

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


