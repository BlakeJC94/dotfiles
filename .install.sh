#!/usr/bin/env sh
# One-time machine setup for a fresh macOS or Linux box.
#
#   1. Installs package managers (Nix, Homebrew on macOS)
#   2. Generates an SSH key for GitLab
#   3. Applies git aliases and pulls the dotfiles repo (bare) into $HOME
#
# POSIX sh compatible — runs under dash/bash/etc. on macOS and Linux.
# Idempotent: safe to re-run.

# --- constants ---------------------------------------------------------------

DOTFILES_REMOTE="git@gitlab.com:blakejc/dotfiles.git"
DOTFILES_BARE="$HOME/.dotfiles"
RAW_BASE="https://gitlab.com/blakejc/dotfiles/-/raw/main"

# --- helpers -----------------------------------------------------------------

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

confirm() {
    # confirm "prompt"  -> returns 0 on yes, 1 on no
    printf '%s (y/N): ' "$1"
    _reply=
    read -r _reply || _reply=
    [ "$_reply" = "y" ] || [ "$_reply" = "Y" ]
}

os_is() {
    # os_is darwin | os_is linux
    case "$(uname -s)" in
        Darwin*) [ "$1" = "darwin" ] ;;
        Linux*)  [ "$1" = "linux" ] ;;
        *) return 1 ;;
    esac
}

have() { command -v "$1" >/dev/null 2>&1; }

fetch() {
    # fetch <url> <dest>  -> returns 0 on success
    curl --silent --show-error --fail --location -o "$2" "$1"
}

# shellcheck disable=SC1090
source_if() { [ -f "$1" ] && . "$1"; }

# Make already-installed tooling available to this script's environment.
source_if "$HOME/.nix-profile/etc/profile.d/nix.sh"
source_if "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
[ -f /opt/homebrew/bin/brew ]    && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -f /usr/local/bin/brew ]      && eval "$(/usr/local/bin/brew shellenv)"

# --- 1. package managers -----------------------------------------------------

install_nix() {
    log "Nix not found."
    if ! confirm "Install Nix?"; then
        log "Skipping Nix installation."
        return 1
    fi
    if os_is darwin; then
        curl --proto '=https' --tlsv1.2 --fail --location \
            https://nixos.org/nix/install | sh
    else
        curl --proto '=https' --tlsv1.2 --fail --location \
            https://nixos.org/nix/install | sh -s -- --no-daemon
    fi
    source_if "$HOME/.nix-profile/etc/profile.d/nix.sh"
    source_if "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
    have nix
}

install_nix_packages() {
    if ! confirm "Install Nix packages?"; then
        log "Skipping Nix packages."
        return 0
    fi
    nixpkgs_dir="$HOME/.config/nixpkgs"
    mkdir -p "$nixpkgs_dir"
    if fetch "$RAW_BASE/.config/nixpkgs/packages.nix?ref_type=heads" "$nixpkgs_dir/packages.nix" \
       && fetch "$RAW_BASE/.config/nixpkgs/config.nix?ref_type=heads"   "$nixpkgs_dir/config.nix"; then
        nix-channel --update
        nix-env -f "$nixpkgs_dir/packages.nix" -i
    else
        log "Failed to download nixpkgs config — skipping Nix packages."
    fi
    rm -rf "$nixpkgs_dir"
}

install_brew() {
    log "Homebrew not found."
    if ! confirm "Install Homebrew?"; then
        log "Skipping Homebrew installation."
        return 1
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -f /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
    have brew
}

install_brew_casks() {
    if ! confirm "Install Homebrew casks?"; then
        log "Skipping casks."
        return 0
    fi
    list_file="$(mktemp)"
    if ! fetch "$RAW_BASE/.listcask?ref_type=heads" "$list_file"; then
        log "Failed to download cask list — skipping casks."
        rm -f "$list_file"
        return 1
    fi
    while IFS= read -r item || [ -n "$item" ]; do
        # skip blank lines and comments
        case "$item" in '' | \#*) continue ;; esac
        # trim surrounding whitespace
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"
        [ -z "$item" ] && continue
        # shellcheck disable=SC2010
        if brew list --cask 2>/dev/null | grep -Fxq "$item" \
           || ls /Applications 2>/dev/null | grep -Fqi "$item"; then
            log "Upgrading $item..."
            brew upgrade --cask "$item" 2>/dev/null || true
        else
            log "Installing $item..."
            brew install --cask "$item"
        fi
    done < "$list_file"
    rm -f "$list_file"
}

# --- 2. ssh keys --------------------------------------------------------------

setup_ssh() {
    log "Setting up SSH keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        log "Existing ed25519 SSH key found."
    else
        ssh-keygen -t ed25519 -C "$USER@$(uname -n)" -f "$HOME/.ssh/id_ed25519" -N ""
    fi
    printf '\nAdd this public key to GitLab (User Settings -> SSH Keys):\n'
    cat "$HOME/.ssh/id_ed25519.pub"
    printf '\n'
    if ! confirm "Done adding the key to GitLab?"; then
        log "Continuing anyway — the dotfiles clone over SSH will fail until the key is added."
    fi
}

# --- 3. git aliases + dotfiles ------------------------------------------------

setup_gitalias() {
    if ! have git; then
        return 0
    fi
    tmp="$(mktemp)"
    if fetch "$RAW_BASE/.gitalias/key?ref_type=heads" "$tmp"; then
        log "Applying git aliases..."
        bash "$tmp"
    else
        log "Could not fetch gitalias script — skipping."
    fi
    rm -f "$tmp"
}

clone_dotfiles() {
    if ! have git; then
        log "git not found — install git before pulling dotfiles."
        return 1
    fi
    if [ -d "$DOTFILES_BARE" ]; then
        log "Dotfiles bare repo already exists at $DOTFILES_BARE — skipping clone."
    else
        log "Cloning dotfiles (bare) into $DOTFILES_BARE..."
        if ! git clone --bare "$DOTFILES_REMOTE" "$DOTFILES_BARE"; then
            log "Clone failed. Make sure your SSH key is added to GitLab and reachable."
            return 1
        fi
    fi

    # Avoid the bare repo scanning $HOME for filesystem changes / untracked files.
    git --git-dir="$DOTFILES_BARE" --work-tree="$HOME" config core.fsmonitor false
    git --git-dir="$DOTFILES_BARE" --work-tree="$HOME" config core.untrackedCache false
    git --git-dir="$DOTFILES_BARE" --work-tree="$HOME" config status.showUntrackedFiles no

    log "Checking out dotfiles into $HOME..."
    if ! git --git-dir="$DOTFILES_BARE" --work-tree="$HOME" checkout; then
        log "Checkout conflicted with existing files in $HOME."
        if have just; then
            just deploy-dotfiles-safe
        else
            log "'just' not found. Resolve the conflicts manually, or install 'just' and run 'just deploy-dotfiles-safe'."
            return 1
        fi
    fi
}

# --- main ---------------------------------------------------------------------

main() {
    # package managers
    if have nix; then
        log "Nix already installed."
        install_nix_packages
    elif install_nix; then
        install_nix_packages
    fi

    if os_is darwin; then
        if have brew; then
            log "Homebrew already installed."
            install_brew_casks
        elif install_brew; then
            install_brew_casks
        fi
    fi

    # ssh keys
    setup_ssh

    # git aliases + dotfiles
    setup_gitalias
    clone_dotfiles

    # marker so the dotfiles know one-time setup completed
    touch "$HOME/.dotfiles.activate"
    log "Setup complete."
}

main "$@"
