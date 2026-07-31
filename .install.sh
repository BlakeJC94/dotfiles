#!/usr/bin/env bash

[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && source "$HOME/.nix-profile/etc/profile.d/nix.sh"
[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix.sh" ] && source "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

## Ask to install nix if not found
if ! command -v nix >/dev/null; then
    echo "Nix not installed"

    printf "Install nix? (y/N): "
    read -r REPLY
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
        else
            curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --no-daemon
        fi
        [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && source "$HOME/.nix-profile/etc/profile.d/nix.sh"
        [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix.sh" ] && source "/nix/var/nix/profiles/default/etc/profile.d/nix.sh"
    else
        return
    fi

    printf "Install nix packages? (y/N): "
    read -r REPLY
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        mkdir -p "$HOME/.config/nixpkgs/"
        curl --silent https://gitlab.com/blakejc/dotfiles/-/blob/main/.config/nixpkgs/packages.nix?ref_type=heads > "$HOME/.config/nixpkgs/packages.nix"
        curl --silent https://gitlab.com/blakejc/dotfiles/-/blob/main/.config/nixpkgs/config.nix?ref_type=heads > "$HOME/.config/nixpkgs/config.nix"
        nix-channel --update
        nix-env -f "$HOME/.config/nixpkgs/packages.nix" -i
    fi
fi

# if mac, install brew
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew >/dev/null; then
        echo "Brew not installed"

        printf "Install brew? (y/N): "
        read -r REPLY
        if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

            echo "Once 'just' is installed, run 'just cask-up'"
            printf "Install brew packages? (y/N): "
            read -r REPLY
            if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then

                while IFS= read -r item; do
                    [ -z "$item" ] && continue
                    if ! brew list --cask | grep -q "^${item}$" && ! ls /Applications | grep -iq "${item}"; then
                        echo "Installing $item..."
                        brew install --cask "${item}"
                    else
                        brew upgrade --cask "${item}"
                    fi
                done < <(curl --silent https://gitlab.com/blakejc/dotfiles/-/raw/main/.listcask?ref_type=heads)
            fi
        fi
    fi
fi

if command -v git >/dev/null; then
    bash <(curl --silent https://gitlab.com/blakejc/dotfiles/-/blob/main/.gitalias/key?ref_type=heads)
    git clone --bare git@gitlab.com:blakejc/dotfiles.git "$HOME/.dotfiles"
    if command -v just >/dev/null; then
        just deploy-dotfiles || just deploy-dotfiles-safe
    fi
fi

touch "$HOME/.dotfiles.activate"
