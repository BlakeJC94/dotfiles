hooks:
    echo "gitdir: $HOME/.dotfiles" > $HOME/.git
    pre-commit install

mise-up:
    mise up

brew-list := "" + "awk" + " " + "watch" + " " + "sk" + " " + "direnv" + " " + "git-lfs" + " " + "bat" + " " + "pre-commit" + " " + "coreutils" + " " + "curl" + " " + "just" + " " + "diffutils" + " " + "eza" + " " + "fd" + " " + "findutils" + " " + "fzf" + " " + "git" + " " + "glow" + " " + "gnu-sed" + " " + "grep" + " " + "jdtls" + " " + "jq" + " " + "less" + " " + "llm" + " " + "mise" + " " + "nano" + " " + "neovim" + " " + "opencode" + " " + "pandoc" + " " + "ripgrep" + " " + "starship" + " " + "tealdeer" + " " + "tree" + " " + "tree-sitter-cli" + " " + "wget"

brew-up:
    #!/usr/bin/env bash
    while IFS= read -r item; do
        [ -z "$item" ] && continue
        if ! brew list --formula | grep -q "^${item}$"; then
            echo "Installing $item..."
            brew install "$item"
        else
            brew upgrade "$item"
        fi
    done < ~/.listbrew


[macos]
cask-up:
    #!/usr/bin/env bash
    while IFS= read -r item; do
        [ -z "$item" ] && continue
        if ! brew list --cask | grep -q "^${item}$" && ! ls /Applications | grep -iq "${item}"; then
            echo "Installing $item..."
            brew install --cask "${item}"
        else
            brew upgrade --cask "${item}"
        fi
    done < ~/.listcask

llm-up:
    #!/usr/bin/env bash
    llm install llm-openrouter
    echo "Setting openrouter key"
    llm keys set openrouter
    llm install llm-tools-searxng
    llm keys set searxng_url --value https://searxng.probableodyssey.net


[linux]
soar-init:
    #!/usr/bin/env bash
    if ! command -v soar > /dev/null; then
        return
    fi
    curl -fsSL "https://raw.githubusercontent.com/pkgforge/soar/main/install.sh" | sh

[linux]
soar-up: soar-init
    #!/usr/bin/env bash
    while IFS= read -r item; do
        [ -z "$item" ] && continue
        echo "Installing ${item}..."
        soar install "${item}"
    done < ~/.listsoar


[linux]
apt-up:
    #!/usr/bin/env bash
    sudo apt update
    while IFS= read -r item; do
        [ -z "$item" ] && continue
        echo "Installing ${item}..."
        sudo apt install -y "${item}"
    done < ~/.listapt

[linux]
spotify-up:
    #!/usr/bin/env bash
    curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt-get update && sudo apt-get install spotify-client

[linux]
write-up:
    #!/usr/bin/env bash
    wget -O write-latest.tar.gz https://www.styluslabs.com/download/write-tgz
    mkdir -p $HOME/.local/opt
    mv write-latest.tar.gz $HOME/.local/opt
    tar xzfv $HOME/.local/opt/write-latest.tar.gz -C $HOME/.local/opt
    sudo $HOME/.local/opt/Write/setup.sh
    xdg-mime default Write.desktop image/svg+xml

[linux]
install-font font="JetBrainsMono":
    #!/usr/bin/env bash
    # Source
    # https://dev.to/pulkitsingh/install-nerd-fonts-or-any-fonts-easily-in-linux-2e3l
    #
    # Added my own tweaks:
    # * Safe exit if the download fails
    # * Specialise to getting releases from https://github.com/ryanoasis/nerd-fonts/releases
    # * Remove sudo, install to local fonts dir instead

    VERSION=$(git hub release view --json tagName --repo ryanoasis/nerd-fonts --jq .tagName)

    # Create a temporary directory
    TEMP_DIR=$(mktemp -d)

    # Download the font zip file
    if ! wget -O "$TEMP_DIR/font.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/$VERSION/{{ font }}.zip"; then
        echo "Failed download"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Unzip the font file
    unzip "$TEMP_DIR/font.zip" -d "$TEMP_DIR" 2>&1 > /dev/null

    # Move the font files to the system fonts directory
    FONTS_DIR="${HOME}/.local/share/fonts"
    mkdir -p "${FONTS_DIR}"
    mv "$TEMP_DIR"/*.{ttf,otf} "${FONTS_DIR}"

    # Update the font cache
    fc-cache -f -v 2>&1 > /dev/null

    # Clean up
    rm -rf "$TEMP_DIR"

    echo "Fonts installed successfully!"

[linux]
purge-snap:
    #!/usr/bin/env bash
    for i in $(seq 10); do echo attmept $i && for j in $(snap list | awk '{print $1}' | tail -n +2); do sudo snap remove --purge $j; done; done
    sudo apt remove -y --purge snapd
    sudo add-apt-repository -y ppa:mozillateam/ppa
    sudo apt update && sudo apt install -y firefox-esr

focus:
    #!/usr/bin/env python
    import argparse
    import os
    import time

    def parse_args():
        parser = argparse.ArgumentParser(description="Breathing exercise utility.")
        parser.add_argument(
            "n_cycles",
            nargs="?",
            type=int,
            default=1,
            help="Number of breathing cycles.",
        )
        parser.add_argument(
            "duration",
            nargs="?",
            type=int,
            default=3,
            help="Duration of each phase",
        )
        return parser.parse_args()

    def clear_screen():
        if os.name == "nt":
            os.system("cls")
        else:
            os.system("clear")

    def text_phase(duration, phase):
        padding = (6 - len(phase)) * " "
        print(f"{phase}{padding} ", end="", flush=True)
        for _ in range(duration):
            print(".", end="", flush=True)
            time.sleep(1)
        print()

    def main():
        args = parse_args()

        n_cycles = args.n_cycles
        duration = args.duration
        clear = args.n_cycles > 1
        if clear:
            clear_screen()

        for i in range(n_cycles):
            if clear:
                print(f"\n{i+1} / {n_cycles}")
            text_phase(duration, "Inhale")
            text_phase(duration, "Hold")
            text_phase(duration, "Exhale")
            text_phase(duration, "Focus")

        if clear:
            clear_screen()

    if __name__ == "__main__":
        main()

# https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
[linux]
docker-up:
    sudo apt install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker ${USER}
    echo "sudo requirement for docker will be dropped on the next reboot"

sync:
    git dotfiles sync

push:
    git dotfiles push

pull:
    git dotfiles pull

st:
    git dotfiles st
