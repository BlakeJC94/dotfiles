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

nnoremap <buffer> <F8> :w<CR> :silent call VimuxRunCommand('bash ' . bufname("%")) <CR>
