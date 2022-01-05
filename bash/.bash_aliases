#!/bin/bash

alias wget="wget2 --progress bar"
alias ll="ls -lahF"
# alias ls="ls"
# alias tree="exa --long --tree"
alias fhere='find . -name '
alias top='htop'
alias publicip="curl http://ipecho.net/plain; echo"
alias localip="ip addr show dev eno1 | grep inet"
alias conky="~/Applications/conky"
alias tailf='_func(){ tail -f "$1" | bat --paging=never -l log ;}; _func'
alias borg_check="echo "---";borg list /mnt/pc_backups/borg/; echo "----";borg info /mnt/pc_backups/borg"
alias hash_check="~/code/bash/hash_check/hash_check"
alias dyfams="~/code/bash/dyfams/dyfams"
alias batdiff="git diff --name-only --diff-filter=d | xargs bat --diff"
alias mac_convert="python $HOME/code/python/ms_to_cisco_mac_converter/main.py"
alias scp="scp -v"
alias dd="dd status=progress"
alias icat="kitty +kitten icat"
alias dust="du -ha | sort -hr | head -n 10"
alias dinopass="curl https://www.dinopass.com/password/strong"

# Git
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gr="git rm"

# Python
alias a="source .venv/bin/activate 2> /dev/null || source \$(git rev-parse --show-toplevel)/.venv/bin/activate"
alias d="deactivate"
alias pipf="pip freeze > ./requirements.txt"
