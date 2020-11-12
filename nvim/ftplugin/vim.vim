setlocal  foldmethod=marker
  " whatever folds you set won't get lost when you quit
autocmd BufWinLeave init.vim mkview
autocmd BufWinEnter init.vim silent loadview 
