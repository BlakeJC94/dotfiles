# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


##
# Settings

if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
    _wezterm_osc7() {
        # Use HOST for zsh, HOSTNAME for bash
        local hostname="${HOST:-$HOSTNAME}"
        printf "\033]7;file://%s%s\033\\" "$hostname" "$PWD"
    }

    # Detect shell type and set up appropriately
    if [[ -n "$BASH_VERSION" ]]; then
        # Bash: use PROMPT_COMMAND
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_wezterm_osc7"
    fi
fi

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# Disable <C-s>/<C-q> from pausing/resuming input to terminal
stty -ixon

# Zsh-like Ctrl-W: delete to previous whitespace
# bind '"\C-w": unix-word-rubout'

# Zsh-like menu completion: Tab shows list then cycles
bind 'set show-all-if-ambiguous on'
bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'   # Shift-Tab

# Case-insensitive completion
bind 'set completion-ignore-case on'

# Colored completions
bind 'set colored-stats on'
bind 'set visible-stats on'

# History search
# bind '"\C-r": reverse-search-history'
# bind '"\C-s": forward-search-history'

source $HOME/.bash/modules/completion.sh
# source $HOME/.bash/modules/tab_cycle.sh

##
# Env vars

# Setup common env vars
[ -f ~/.vars ] && source ~/.vars


##
# Aliases

# Setup common alias definitions
[ -f ~/.aliases ] && source ~/.aliases


##
# Initialisers

# Linuxbrew
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Mise
eval "$(mise activate bash)"
# source <(mise completion bash --include-bash-completion-lib)

# Initialise Starship prompt
eval "$(starship init bash)"

# Initialise FZF
source <(fzf --bash)

# Initialise WSL
[ -f $HOME/.local/bin/wezterm-wsl ] && $HOME/.local/bin/wezterm-wsl

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/blake/google-cloud-sdk/path.bash.inc' ]; then . '/home/blake/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/blake/google-cloud-sdk/completion.bash.inc' ]; then . '/home/blake/google-cloud-sdk/completion.bash.inc'; fi
