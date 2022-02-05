#!/bin/bash

alias wget="wget2 --progress bar"
alias ll="ls -lahF"
alias fhere='find . -name '
alias publicip="curl http://ipecho.net/plain; echo"
alias localip="ip -4 -br addr show dev eno1"
alias conky="~/Applications/conky"
alias borg_check="echo "---";borg list /mnt/pc_backups/borg/; echo "----";borg info /mnt/pc_backups/borg"
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
alias gd="git diff"

# Python
if [[ $(uname -o) == 'Msys' ]]; then
  alias a="source .venv/Scripts/activate 2> /dev/null || source \$(git rev-parse --show-toplevel)/.venv/Scripts/activate"
else
  alias a="source .venv/bin/activate 2> /dev/null || source \$(git rev-parse --show-toplevel)/.venv/bin/activate"
fi
alias d="deactivate"
alias pipf="pip freeze --exclude python-dotenv > ./requirements.txt"
