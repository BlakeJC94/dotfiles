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

# Initialise brew and tools
source ~/.brewtstrap

# Initialise tools if requested
if [ -f ~/.dotfiles-activate ]; then
    source ~/.zshrc.activate
fi


##
# Extras

# License Vault URL for activation of Jetbrains products at Canva
export JETBRAINS_LICENSE_SERVER=https://canva.fls.jetbrains.com/
