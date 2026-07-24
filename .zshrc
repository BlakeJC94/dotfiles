# ~/.zshrc: executed by zsh(1) for non-login shells.
#
# My Zsh configuration is tailored to MacOS, but it should work on Linux
#

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


##
# Settings

# Ensure the emacs bindings are working
bindkey -e

# Up/down arrows match partially typed commands
autoload -Uz history-beginning-search-backward history-beginning-search-forward
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward


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

if [ -f ~/.dotfiles.activate ]; then
    # Initialise packages
    source ~/.bootstrap

    # Initialise tools if requested
    source ~/.zshrc.activate
fi


##
# Extras

# Local overrides
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
