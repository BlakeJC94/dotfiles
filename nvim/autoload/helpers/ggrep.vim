function helpers#ggrep#GgrepHelper()
  exe 'Ggrep ' . expand('<cword>')
  :copen
endfunction
