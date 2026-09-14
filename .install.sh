#!/usr/bin/env sh
# One-time machine setup for a fresh macOS or Linux box.
#
#   1. Installs package managers (Homebrew on macOS and Linux)
#   2. Generates an SSH key for GitLab
#   3. Pulls the dotfiles repo (bare) into $HOME
#
# POSIX sh compatible — runs under dash/bash/etc. on macOS and Linux.
# Idempotent: safe to re-run.

# --- constants ---------------------------------------------------------------

DOTFILES_REMOTE="git@gitlab.com:blakejc/dotfiles.git"
DOTFILES_BARE="$HOME/.dotfiles"

BREW_PACKAGES=$(cat <<'EOF'
awk
bat
coreutils
curl
delta
diffutils
direnv
dprint
eza
tre-command
fd
sd
entr
rsync
findutils
gaze
git
git-lfs
gitleaks
glances
gnu-sed
grep
herdr
httpie
ipython
jdtls
jless
jq
jsongrep
julia
just
less
llm
llmfit
lua-language-server
marksman
mise
monolith
nano
neovim
pandoc
pi-coding-agent
pre-commit
python-lsp-server
ripgrep
ruff
sheets
shellcheck
sk
slides
starship
stylua
taplo
tealdeer
tree
tree-sitter-cli
trex
uv
watch
wget
write-good
z
EOF
)

BREW_CASKS=$(cat <<'EOF'
bitwarden
caffeine
docker
firefox
font-jetbrains-mono-nerd-font
fuse
ghostty
macmediakeyforwarder
protonvpn
spotify
tailscale
EOF
)

is_mac() { os_is darwin; }

APT_PACKAGES=$(cat <<'EOF'
build-essential
net-tools
wget
xclip
EOF
)

UV_PACKAGES=$(cat <<'EOF'
files-to-prompt
strip-tags
symbex
EOF
)

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
    Linux*) [ "$1" = "linux" ] ;;
    *) return 1 ;;
    esac
}

have() { command -v "$1" >/dev/null 2>&1; }

# Make already-installed tooling available to this script's environment.
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -f /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"

# --- 1. package managers -----------------------------------------------------

install_brew() {
    log "Homebrew not found."
    if ! confirm "Install Homebrew?"; then
        log "Skipping Homebrew installation."
        return 1
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [ -f /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
    have brew
}

install_brew_packages() {
    while IFS= read -r item || [ -n "$item" ]; do
        if brew list 2>/dev/null | grep -Fxq "$item"; then
            log "Upgrading $item..."
            brew upgrade "$item" </dev/null 2>/dev/null || true
        else
            log "Installing $item..."
            brew install "$item" </dev/null || true
        fi
    done <<EOF
$BREW_PACKAGES
EOF
}

install_brew_casks() {
    if ! is_mac; then
        log "Homebrew casks are only supported on macOS."
        return 0
    fi

    while IFS= read -r item || [ -n "$item" ]; do
        if brew list --cask 2>/dev/null | grep -Fxq "$item" ||
            ls /Applications 2>/dev/null | grep -Fqi "$item"; then
            log "Upgrading $item..."
            brew upgrade --cask "$item" </dev/null 2>/dev/null || true
        else
            log "Installing $item..."
            brew install --cask "$item" </dev/null || true
        fi
    done <<EOF
$BREW_CASKS
EOF
}



install_apt_packages() {
    if ! os_is linux; then
        log "apt packages are only supported on Linux."
        return 0
    fi
    if ! have apt-get; then
        log "apt-get not found — skipping apt packages."
        return 0
    fi

    if have sudo; then
        sudo="sudo"
    else
        log "sudo not found — assuming running as root."
        sudo=
    fi

    log "Updating apt package index..."
    $sudo apt-get update </dev/null

    while IFS= read -r item || [ -n "$item" ]; do
        if dpkg -s "$item" >/dev/null 2>&1; then
            log "$item is already installed."
        else
            log "Installing $item..."
            $sudo apt-get install -y "$item" </dev/null || true
        fi
    done <<EOF
$APT_PACKAGES
EOF
}


install_uv_packages() {
    while IFS= read -r item || [ -n "$item" ]; do
        if uv tool list 2>/dev/null | grep '^-' | sed 's/^-\s*//' | grep -Fxq "$item"; then
            log "Upgrading $item..."
            brew upgrade "$item" </dev/null 2>/dev/null || true
        else
            log "Installing $item..."
            uv tool upgrade "$item" </dev/null || true
        fi
    done <<EOF
$UV_PACKAGES
EOF
}

# --- 2. ssh keys --------------------------------------------------------------

setup_ssh() {
    log "Setting up SSH keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    write=true
    if [ -f "${HOME}/.ssh/id_ed25519" ]; then
        printf "Do you want to overwrite it? (y/N): "
        read -r REPLY
        if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
            write=true
        else
            write=false
        fi
    fi

    if [ "$write" = "true" ]; then
        printf "Enter your email address: "
        read -r email
        if [ -z "$email" ]; then
            echo "ERROR: Email address is required"
            exit 1
        fi
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        echo "Generating SSH key..."
        ssh-keygen -t ed25519 -C "$email" -f "${HOME}/.ssh/id_ed25519"
    fi

    echo
    echo "Your public SSH key:"
    echo "===================="
    cat "${HOME}/.ssh/id_ed25519.pub"
    echo "===================="
    echo
    echo "Add this key to"
    echo "  - https://gitlab.com/-/user_settings/ssh_keys"
    echo "  - https://github.com/settings/ssh/new"
    echo
}

# --- 3. dotfiles --------------------------------------------------------------

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

    # Configure githooks
    git --git-dir="$DOTFILES_BARE" --work-tree="$HOME" config core.hooksPath "$HOME/.githooks"

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

usage() {
    printf '%s\n' "Usage: $0 [--brew-packages] [--brew-casks] [--ssh-keys] [--apt-packages]"
}

main() {
    case "${1:-}" in
    --brew-packages)
        [ "$#" -eq 1 ] || { usage; return 1; }
        install_brew_packages
        return
        ;;
    --brew-casks)
        [ "$#" -eq 1 ] || { usage; return 1; }
        install_brew_casks
        return
        ;;
    --ssh-keys)
        [ "$#" -eq 1 ] || { usage; return 1; }
        setup_ssh
        return
        ;;
    --apt-packages)
        [ "$#" -eq 1 ] || { usage; return 1; }
        install_apt_packages
        return
        ;;
    --uv-packages)
        [ "$#" -eq 1 ] || { usage; return 1; }
        install_uv_packages
        return
        ;;
    "")
        ;;
    *)
        usage
        return 1
        ;;
    esac

    # apt packages (Linux only, before brew — linuxbrew needs build tools)
    if os_is linux; then
        if confirm "Install apt packages?"; then
            install_apt_packages
        else
            log "Skipping apt packages."
        fi
    fi

    if have brew; then
        log "Homebrew already installed."

        if ! confirm "Install Homebrew packages?"; then
            log "Skipping packages."
        else
            install_brew_packages
        fi

        if ! confirm "Install Homebrew casks?"; then
            log "Skipping casks."
        else
            install_brew_casks
        fi

        if ! confirm "Install UV packages?"; then
            log "Skipping packages."
        else
            install_uv_packages
        fi

    elif install_brew; then
        log "Homebrew installed."

        if ! confirm "Install Homebrew packages?"; then
            log "Skipping packages."
        else
            install_brew_packages
        fi

        if ! confirm "Install Homebrew casks?"; then
            log "Skipping casks."
        else
            install_brew_casks
        fi

        if ! confirm "Install UV packages?"; then
            log "Skipping packages."
        else
            install_uv_packages
        fi
    fi

    # ssh keys
    setup_ssh
    if ! confirm "Done adding the key to GitLab?"; then
        log "Continuing anyway — the dotfiles clone over SSH will fail until the key is added."
    fi

    # dotfiles
    clone_dotfiles

    # marker so the dotfiles know one-time setup completed
    touch "$HOME/.dotfiles.activate"
    log "Setup complete."
}

main "$@"
