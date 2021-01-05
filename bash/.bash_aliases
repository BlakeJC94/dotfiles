#custom aliases

alias wget="wget2"
# alias ll='ls -lah'
alias ll="exa -al --classify --icons --git --color-scale"
alias ls="exa --oneline --classify"
alias fhere='find . -name '
alias top='htop'
alias myip="curl http://ipecho.net/plain; echo"
alias map_it="~/code/automations/map_it/venv/bin/python ~/code/automations/map_it/map_it.py"
alias pdf_fixer="~/code/automations/pdf_fixer/venv/bin/python ~/code/automations/pdf_fixer/pdf_fixer.py"
alias nvim="~/Applications/nvim"
alias conky="~/Applications/conky"
alias pip="pip3"
alias pdf_paranoia="~/code/automations/pdf_paranoia/venv/bin/python ~/code/automations/pdf_paranoia/pdf_paranoia.py"
alias md_table_gen="~/code/automations/md_table_gen/venv/bin/python ~/code/automations/md_table_gen/md_table_gen.py"
alias quick_weather="~/code/automations/quick_weather/venv/bin/python ~/code/automations/quick_weather/quick_weather.py"
alias auto_unsubscriber="~/code/automations/auto_unsubscriber/venv/bin/python ~/code/automations/auto_unsubscriber/auto_unsubscriber.py"
alias tmux_py="bash $CONF/tmux/tmux_sessions/python_session.sh"
alias tmux_menu="bash $CONF/tmux/tmux_session.sh"
alias cdl='_func(){ cd "$1" && ll ;}; _func'
alias borg="~/.virtualenvs/borg/bin/python ~/.virtualenvs/borg/bin/borg"
alias borg_check="echo "---";borg list /mnt/pc_backups/borg/; echo "----";borg info /mnt/pc_backups/borg"
alias hash_check="~/code/bash/hash_check/hash_check"
alias gsa="~/code/bash/git_status_all/git_status_all"


# Automatically activate Git projects' virtual environments based on the
# directory name of the project. Virtual environment name can be overridden
# by placing a .venv file in the project root with a virtualenv name in it
function workon_cwd {
  # Check that this is a Git repo
  GIT_DIR=`git rev-parse --git-dir 2> /dev/null`
  if [ $? == 0 ]; then
    # Find the repo root and check for virtualenv name override
      GIT_DIR=`\cd $GIT_DIR; pwd`
      PROJECT_ROOT=`dirname "$GIT_DIR"`
      ENV_NAME=`basename "$PROJECT_ROOT"`
      if [ -f "$PROJECT_ROOT/.venv" ]; then
          ENV_NAME=`cat "$PROJECT_ROOT/.venv"`
      fi
      # Activate the environment only if it is not already active
      if [ "$VIRTUAL_ENV" != "$WORKON_HOME/$ENV_NAME" ]; then
        if [ -e "$WORKON_HOME/$ENV_NAME/bin/activate" ]; then
          workon "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
        fi
      fi
   elif [ $CD_VIRTUAL_ENV ]; then
   # We've just left the repo, deactivate the environment
   # Note: this only happens if the virtualenv was activated automatically
     deactivate && unset CD_VIRTUAL_ENV
   fi
}

# New cd function that does the virtualenv magic
function venv_cd {
  cd "$@" && workon_cwd
}

alias cd="venv_cd"
