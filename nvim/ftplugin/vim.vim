setlocal  foldmethod=marker
  " whatever folds you set won't get lost when you quit
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview 
