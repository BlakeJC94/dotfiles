function! AddChangesToDotfiles()
  let current_file = expand('%')
  if (system('chezmoi managed ' . current_file) != '') && (system('chezmoi diff ' . current_file) != '')
    execute 'silent !chezmoi add ' . current_file
    echo 'Added to dotfiles'
  endif
endfunction

augroup add_changes_to_dotfiles
  autocmd!
  autocmd BufWritePost * call AddChangesToDotfiles()
augroup END
