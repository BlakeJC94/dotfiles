command! DotPull !chezmoi update
command! DotPush !chezmoi git sync


function! AddChangesToDotfiles()
  let current_file = expand('%')
  let managed_result = systemlist('chezmoi managed ' . shellescape(current_file))
  let diff_result = systemlist('chezmoi diff ' . shellescape(current_file))

  if !empty(managed_result) && !empty(diff_result)
    call system('chezmoi add ' . shellescape(current_file))
    echo 'Added to dotfiles'
  endif
endfunction

augroup add_changes_to_dotfiles
  autocmd!
  autocmd BufWritePost * call AddChangesToDotfiles()
augroup END


function! ApplyChangesFromDotfiles()
  let target_path = systemlist('chezmoi target-path ' . shellescape(expand('%')))
  if !empty(target_path)
    call system('chezmoi apply ' . shellescape(target_path[0]))
    redraw!
    echo 'Applied from dotfiles'
  endif
endfunction

augroup apply_changes_from_dotfiles
  autocmd!
  autocmd BufWritePost ~/.local/share/chezmoi/* call ApplyChangesFromDotfiles()
augroup END


function! DotfilesSetFiletype()
  let l:realpath = trim(system('chezmoi target-path ' . shellescape(expand('%:p'))))
  execute 'setfiletype ' fnameescape(fnamemodify(l:realpath, ':t'))
endfunction

augroup dotfiles_set_filetype
  autocmd!
  autocmd BufRead,BufNewFile ~/.local/share/chezmoi/* call DotfilesSetFiletype()
augroup END
