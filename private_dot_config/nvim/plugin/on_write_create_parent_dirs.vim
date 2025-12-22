function! s:CreateDirs()
  let dir = expand('<afile>:p:h')
  if isdirectory(dir) == 0 && dir !~ ':'
    let choice = confirm('Create directory "' . dir . '"?', "&Yes\n&No", 1)
    if choice == 1
      call mkdir(dir, 'p')
    endif
  endif
endfunction

augroup create_dirs_on_write
  autocmd!
  autocmd BufWritePre,FileWritePre * call s:CreateDirs()
augroup END
