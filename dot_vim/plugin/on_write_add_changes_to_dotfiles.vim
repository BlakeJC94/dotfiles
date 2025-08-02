nnoremap <Leader>; <cmd>edit ~/.vim/vimrc <bar> lcd %:p:h<CR>
nnoremap <Leader>: <cmd>exec 'edit ' . system("chezmoi source-path")<CR>

command! DotPull !chezmoi update
command! DotPush !chezmoi git sync


function! AddChangesToDotfiles()
  let current_file = expand('%')
  if (system('chezmoi managed ' . current_file) !=? '') && (system('chezmoi diff ' . current_file) != '')
    execute 'silent !chezmoi add ' . current_file
    echo 'Added to dotfiles'
  endif
endfunction

augroup add_changes_to_dotfiles
  autocmd!
  autocmd BufWritePost * call AddChangesToDotfiles()
augroup END


function! ApplyChangesFromDotfiles()
  execute 'silent !chezmoi target-path ' . expand('%') . ' | chezmoi apply'
  echo 'Applied from dotfiles'
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
