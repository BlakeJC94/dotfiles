augroup on_quit_kill_nvim_terminals
  autocmd!
  autocmd VimLeavePre * call s:KillTerminals()
augroup END

function! s:KillTerminals() abort
  for bufnr in range(1, bufnr('$'))
    if bufloaded(bufnr) && getbufvar(bufnr, '&buftype') ==# 'terminal'
      execute 'bdelete!' bufnr
    endif
  endfor
endfunction
