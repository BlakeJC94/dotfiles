# Dotfiles

Dotfiles for my various systems, feel free to browse for inspiration (Clone and
use them at your own risk though)

## Pre-requisites

Debian:

```bash
sudo apt update && sudo apt install -y git grep curl
```

MacOS:

```bash
brew install git grep curl
```

WSL:

```text
TODO
```

## Setup

First authenticate new machine with github:

```bash
curl -sSL https://raw.githubusercontent.com/BlakeJC94/dotfiles/refs/heads/main/.gitsetup.sh | bash
```

Setup the `dot` alias:

```bash
source <(curl -sSL https://raw.githubusercontent.com/BlakeJC94/dotfiles/refs/heads/main/.aliases | grep '^alias dot=')
```

Clone dotfiles to new machine:

```bash
git clone --bare git@github.com:BlakeJC94/dotfiles.git $HOME/.dotfiles
dot checkout
```

If there are conflicts:

```bash
mkdir -p .config-backup
dot checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | \
  xargs -I{} mv {} .config-backup/{}
dot checkout
```

Install brew

```bash
bash .brewsetup.sh
bash .brewtools.sh
```

Install tools from `mise`

```bash
mise up
```

Source the shell RC to get all the settings and whatnot (or start a new shell)

```bash
source .bashrc  # If on bash
source .zshrc   # If on zsh
```

## Usage

Add a file to the dotfile repo:

```bash
echo "!/path/to/file" >> .gitignore
dot add /path/to/file
dot commit -m "feat: Add file"
```

Remove a file from the dotfile repo

```bash
```
