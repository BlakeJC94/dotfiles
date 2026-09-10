# ~/.bashrc: executed by bash(1) for non-login shells.
#
# My Bash configuration is tailored to Linux, but it should work on MacOS
#

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

##
# Env vars

# Setup common env vars
[ -f ~/.vars ] && source ~/.vars
[ -f ~/.vars.local ] && source ~/.vars.local

##
# Aliases

# Setup common alias definitions
[ -f ~/.aliases ] && source ~/.aliases
[ -f ~/.aliases.local ] && source ~/.aliases.local

##
# Only load terminal/ZLE configuration in a real interactive terminal

[[ $- == *i* && -t 0 ]] || return

##
# Initialisers

if [ -f ~/.dotfiles.activate ]; then
    source ~/.bashrc.activate
    [ -f ~/.bashrc.activate.local ] && source ~/.bashrc.activate.local
fi

##
# Extras

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
bind '"\e[Z": menu-complete-backward' # Shift-Tab

# Case-insensitive completion
bind 'set completion-ignore-case on'

# Colored completions
bind 'set colored-stats on'
bind 'set visible-stats on'

