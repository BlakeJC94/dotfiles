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
setl nofoldenable

" highlight OverLength ctermbg=darkgrey guibg=#ff4ea5
" match OverLength /\%80v.*/

"Override default pythonDot color
highlight link pythonDot Red

"Only use these fixers
let b:ale_fixers = ['autopep8', 'isort', 'black', 'add_blank_lines_for_python_control_statements', 'remove_trailing_lines', 'trim_whitespace']

"Only use these linters
let b:ale_linters = ['mypy', 'flake8', 'pydocstyle']

""TODO: make these functions not echo the text
"function! Run_python()
"  let select = helpers#tmux_panes#check_panes()
"  exe ' !' . select . 'tmux send-keys -t 2 C-m "python "' . expand('%')
"endfunction

"function! Run_python_tests()
"  let select = helpers#tmux_panes#check_panes()
"  exe ' !' . select . 'tmux send-keys -t 2 C-m "py.test -v"'
"endfunction

nnoremap <F8> :w<CR> :silent call VimuxRunCommand('python ' . bufname("%")) <CR>

nnoremap <F7> :w<CR> :silent call VimuxRunCommandInDir('py.test -v', 0)<CR>


