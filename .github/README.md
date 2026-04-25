# Dotfiles

Dotfiles for my various systems, feel free to browse for inspiration (Clone and
use them at your own risk though)

## Pre-requisites

Debian:

```bash
sudo apt update && sudo apt install -y git
```

MacOS:

```bash
brew install git
```

WSL:

```text
TODO
```

## Setup

First authenticate new machine with Github:

```bash
curl -sSL https://raw.githubusercontent.com/BlakeJC94/dotfiles/refs/heads/main/.local/bin/git-up | bash
```

Clone dotfiles to new machine and setup the `dit` alias:

```bash
git clone --bare git@github.com:BlakeJC94/dotfiles.git $HOME/.dotfiles
alias dit='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dit checkout
```

If there are conflicts, destroy current state with `dit checkout --force`.
Otherwise, here's a non-destructive command to use:

```bash
mkdir -p .config-backup
dit checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | while read -r file; do
  mkdir -p ".config-backup/$(dirname "$file")"
  mv "$file" ".config-backup/$file"
done
dit checkout
```

Add a pointer to the bare repo so that git tools (such as the `git` plugin for
`starship`, or `vim-fugitive` for `vim`/`nvim`):

```bash
echo "gitdir: $HOME/.dotfiles" > $HOME/.git
```

Source the shell RC to get all the settings and whatnot (or start a new shell)

```bash
source .bashrc  # If on bash
source .zshrc   # If on zsh
```

Install brew

```bash
brew-up

```

Install tools from `mise`

```bash
mise up
```

## Usage

Add a file to the dotfile repo:

```bash
echo "!/path/to/file" >> .gitignore
dit add /path/to/file
dit commit -m "feat: Add file"
```

Remove a file from the dotfile repo by removing it from the gitignore file
