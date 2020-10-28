function! helpers#lightline#gitBranch()
    return "\uE725" . (exists('*fugitive#head') ? ' ' . fugitive#head() : '' )
endfunction
