#!/bin/bash
PS3='Which session would you like? '
options=("python" "linux" "Quit")

select session in "${options[@]}"; do
    case $session in
        "python")
            echo "Starting $session session!"
            $CONF/tmux/tmux_sessions/python_session.sh
            break
            ;;
        "linux")
            echo "Starting $session session!"
	          break
	    # optionally call a function or run some code here
            ;;
        "Quit")
            echo "User requested exit"
	          exit
	          ;;
        *) echo "invalid option $REPLY";;
    esac
done
