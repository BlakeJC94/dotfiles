augroup add_changes_to_dotfiles
  autocmd!
  autocmd BufWritePost * if ((system('chezmoi managed ' . expand('%')) != '') && (system('chezmoi diff ' . expand('%')) != ''))  | execute 'silent !chezmoi add %' | echo 'Added to dotfiles' | endif
augroup END
