function! helpers#lightline#gitBranch()
  if exists('*FugitiveHead')
    if len(FugitiveHead()) ==# 0
      return ''
    else
      return "\uE725" . ' ' . FugitiveHead()
    endif
  endif
endfunction

function! helpers#lightline#venv()
  if expand("%:e") ==# 'py'
    if b:venv_available ==# 1
      return "venv: " . "\u2705"
    else
      return "venv: " . "\u274C"
    endif
  else
    return ''
  endif
endfunction
