# ~/.bashrc: executed by bash(1) for non-login shells.
#
# My Bash configuration is tailored to Linux, but it should work on MacOS
#

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


##
# Settings

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# Disable <C-s>/<C-q> from pausing/resuming input to terminal
stty -ixon

# Zsh-like menu completion: Tab shows list then cycles
bind 'set show-all-if-ambiguous on'
bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'   # Shift-Tab

# Case-insensitive completion
bind 'set completion-ignore-case on'

# Colored completions
bind 'set colored-stats on'
bind 'set visible-stats on'


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

# Initialise tools if requested
if [ -f ~/.dotfiles-activate ]; then
    source ~/.bashrc.activate
fi

