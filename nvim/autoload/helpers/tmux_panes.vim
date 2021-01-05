" function! helpers#tmux_panes#check_panes()
"     let panes=system('tmux list-panes')
"     let panes_list = split(panes, '\n')
"     if len(panes_list) > 1
"       echo 'Found second pane'
"     else
"       echo 'One pane'
"     endif
" endfunction

function helpers#tmux_panes#check_panes()
    let panes = system('tmux list-panes')
    if panes =~ '2:'
      return 'tmux select-pane -t 2;'
    else
      return 'tmux split-window -v;'
    endif
endfunction
