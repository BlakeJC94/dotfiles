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

# Enable autocomplete for commands
autoload -Uz compinit && compinit

# Ensure the emacs bindings are working
bindkey -e

# Up/down arrows match partially typed commands
autoload -Uz history-beginning-search-backward history-beginning-search-forward
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# Ctrl+Left/Right move by word (ghostty terminfo lacks kLFT5/kRIT5)
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word


##
# Env vars

[ -f ~/.vars ] && source ~/.vars
[ -f ~/.vars.local ] && source ~/.vars.local

##
# Aliases

[ -f ~/.aliases ] && source ~/.aliases
[ -f ~/.aliases.local ] && source ~/.aliases.local

##
# Only load terminal/ZLE configuration in a real interactive terminal

[[ -o interactive && -t 0 ]] || return

##
# Initialisers

if [ -f ~/.dotfiles.activate ]; then
    source ~/.zshrc.activate
    [ -f ~/.zshrc.activate.local ] && source ~/.zshrc.activate.local
fi

# BEGIN ANSIBLE MANAGED BLOCK FOR canva_git
export PATH="$HOME/.local/share/canva-git/bin:$PATH"
# END ANSIBLE MANAGED BLOCK FOR canva_git
