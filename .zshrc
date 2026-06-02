# ~/.zshrc: executed by zsh(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac


##
# Settings


# Ensure the emacs bindings are working
bindkey -e

# Bind delete key properly in TMUX
if [[ -n $TMUX ]]; then
    bindkey '^[[3~' delete-char
fi


##
# Env vars

# Setup common env vars
[ -f ~/.vars ] && source ~/.vars

# Replace MacOS standard tools with Unix standard tools
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"

# Setup LS colors
eval $(dircolors)

# Enable using numpy for ips-tunnelling
export CLOUDSDK_PYTHON_SITEPACKAGES=1


##
# Aliases

# Setup common alias definitions
[ -f ~/.aliases ] && source ~/.aliases


##
# Initialisers

# Intiliase Brew package manager
eval "$(/opt/homebrew/bin/brew shellenv)"

# Initialise Mise NOTE: If you run into this issue:
#
#     The application panicked (crashed). Message: remote was just created and
#     must be visible in config: Find(RefSpec { kind: "fetch", remote_name:
#     "origin", source: Error { key: "remote.<name>.fetch", value:
#     Some("^refs/heads/mergeQueue-*"), environment_override: None, source:
#     Some(NegativeGlobPattern) } }) Location:
#     /Users/brew/Library/Caches/Homebrew/cargo_cache/registry/src/index.crates.io-1949cf8c6b5b557f/gix-0.83.0/src/clone/fetch/util.rs:252
#
# Diagnose which config is causing the issue with
#
#    git config --show-origin --get-all remote.origin.fetch
#
# And remove the entry
#
#     [remote "origin"]
#         fetch = ^refs/heads/mergeQueue-*
#
eval "$(mise activate zsh)"

# Initialise Starship prompt
eval "$(starship init zsh)"

# Initialise FZF
source <(fzf --zsh)


##
# Extras

# License Vault URL for activation of Jetbrains products at Canva
export JETBRAINS_LICENSE_SERVER=https://canva.fls.jetbrains.com/
