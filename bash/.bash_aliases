#custom aliases

alias wget="wget2"
# alias ll='ls -lah'
alias ll="exa -al --classify --git --color-scale"
alias ls="exa --oneline --classify"
alias tree="exa --long --tree"
alias fhere='find . -name '
alias top='htop'
alias myip="curl http://ipecho.net/plain; echo"
alias nvim="~/Applications/nvim"
alias conky="~/Applications/conky"
alias pip="pip3"
alias cdl='_func(){ cd "$1" && ll ;}; _func'
alias tailf='_func(){ tail -f "$1" | bat --paging=never -l log ;}; _func'
alias borg_check="echo "---";borg list /mnt/pc_backups/borg/; echo "----";borg info /mnt/pc_backups/borg"
alias hash_check="~/code/bash/hash_check/hash_check"
alias gsa="~/code/bash/git_status_all/git_status_all"
alias dyfams="~/code/bash/dyfams/dyfams"
alias batdiff="git diff --name-only --diff-filter=d | xargs bat --diff"
alias gcgp="git commit && git push"
alias mac_convert="python $HOME/code/python/ms_to_cisco_mac_converter/main.py"
alias new_project="cookiecutter cookiecutter-pypackage-custom --directory $HOME/.config/cookiecutter/cookiecutter-pypackage-custom"
alias ra=". $HOME/.config/bash/.bash_aliases"


# Automatically activate Git projects' virtual environments based on the
# directory name of the project. Virtual environment name can be overridden
# by placing a .venv file in the project root with a virtualenv name in it
# workon_cwd() {
#   # Check that this is a Git repo
#   GIT_DIR=`git rev-parse --git-dir 2> /dev/null`
#   if [ $? == 0 ]; then
#     # Find the repo root and check for virtualenv name override
#       GIT_DIR=`\cd $GIT_DIR; pwd`
#       PROJECT_ROOT=`dirname "$GIT_DIR"`
#       ENV_NAME=`basename "$PROJECT_ROOT"`
#       if [ -f "$PROJECT_ROOT/.venv" ]; then
#           ENV_NAME=`cat "$PROJECT_ROOT/.venv"`
#       fi
#       # Activate the environment only if it is not already active
#       if [ "$VIRTUAL_ENV" != "$WORKON_HOME/$ENV_NAME" ]; then
#         if [ -e "$WORKON_HOME/$ENV_NAME/bin/activate" ]; then
#           workon "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
#         fi
#       fi
#    elif [ $CD_VIRTUAL_ENV ]; then
#    # We've just left the repo, deactivate the environment
#    # Note: this only happens if the virtualenv was activated automatically
#      deactivate && unset CD_VIRTUAL_ENV
#    fi
# }

# # New cd function that does the virtualenv magic
# venv_cd() {
#   cd "$@" && workon_cwd
# }

# alias cd="venv_cd"
