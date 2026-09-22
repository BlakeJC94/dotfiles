# Sourced by every zsh spawned from inside nvim (via $ZDOTDIR) so that
# non-interactive shells (e.g. :! commands) can use the aliases in
# ~/.aliases. zsh expands aliases in non-interactive shells too, but only
# sources .zshenv (not .zshrc) for them, which is why we source here.

# Chain the real ~/.zshenv if one ever exists
[ -f ~/.zshenv ] && source ~/.zshenv

[ -f ~/.aliases ] && source ~/.aliases

# Restore ZDOTDIR so interactive shells (:terminal) read the real
# ~/.zprofile / ~/.zshrc instead of this directory
ZDOTDIR=$HOME
