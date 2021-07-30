"""""""""""""""""""""""""""
"  Shell Script Settings  "
"""""""""""""""""""""""""""

setl tabstop=2
setl softtabstop=2
setl shiftwidth=2
setl expandtab
setl autoindent
setl fileformat=unix
setl formatoptions+=t
setl textwidth=80
setl cc=+1
setl nofoldenable

let b:ale_fixers = ['shfmt', 'remove_trailing_lines', 'trim_whitespace']

nnoremap <buffer> <F8> :w<CR> :silent call Run_bash_script() <CR>

function! Run_bash_script()
  let pane = helpers#tmux_panes#check_panes()
  exe ' !' . pane . 'tmux send-keys -t 2 "clear; bash "' . 
        \ expand('%') . ' C-m'
endfunction
