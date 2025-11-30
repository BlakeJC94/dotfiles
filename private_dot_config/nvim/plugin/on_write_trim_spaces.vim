function! s:TrimSpaces()
  let winstate = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(winstate)
endfunction
augroup trim_spaces_on_write
  autocmd!
  autocmd BufWritePre * if index(['make'], &ft) < 0 | retab | endif
  autocmd BufWritePre * call s:TrimSpaces()
  autocmd BufWritePre * %s/\n\+\%$/\r/e | if getline('$') == '' | $d | endif
augroup END
