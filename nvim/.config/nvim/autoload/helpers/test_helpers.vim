" function helpers#test_helpers#RunAllTests(test_exe)
"   let tester = a:test_exe
"   if b:project_root != ''
"     execute 'Start -wait=always cd ' . b:project_root . '; poetry run ' . tester
"   endif
" endfunction
