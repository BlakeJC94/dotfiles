#!/bin/bash

SESSION=python

#Start new session detached
tmux new -s $SESSION -d

#Split across middle
tmux split-window -v -t $SESSION

#Split lower half vertically
tmux split-window -h -t $SESSION

#Select first pane
tmux select-pane -t 1 

#Start nvim in pane 1
tmux send-keys -t $SESSION 'nvim' C-m

#Select pane 2 and start python
tmux select-pane -t 2 
#TODO: check for venv
tmux send-keys -t $SESSION 'python3' C-m

#Select pane 3 and start bash
tmux select-pane -t 3
tmux send-keys -t $SESSION 'bash' C-m

tmux select-pane -t 1 
tmux resize-pane -Z

tmux attach -t $SESSION
