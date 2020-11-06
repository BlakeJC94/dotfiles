function! helpers#lightline#gitBranch()
  if exists('*FugitiveHead')
    if len(FugitiveHead()) == 0
      return ''
    else
      return "\uE725" . ' ' . FugitiveHead()
    endif
  endif
endfunction
