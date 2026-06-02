# Dotfiles

Dotfiles for my various systems, feel free to browse for inspiration (Clone and
use them at your own risk though)

## Setup

First install `git` and `curl`, then authenticate new machine with the remote:

```
curl "https://gitlab.com/blakejc/dotfiles/-/raw/main/.gitconfig?ref_type=heads" > .gitconfig
git key
rm .gitconfig
git clone --bare git@gitlab.com:blakejc/dotfiles.git $HOME/.dotfiles
```

Clone dotfiles to new machine:

```bash
git dotfiles checkout
```

If there are conflicts, destroy current state with `git dotfiles checkout --force`.
Otherwise, here's a non-destructive command to use:

```bash
mkdir -p .config-backup
git dotfiles checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | while read -r file; do
  mkdir -p ".config-backup/$(dirname "$file")"
  mv "$file" ".config-backup/$file"
done
git dotfiles checkout
```

Make sure pre-commit is installed and install the git hooks

```bash
pre-commit install
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
up-brew

```

Install tools from `mise`

```bash
mise up
```

## Usage

Add a file to the dotfile repo:

```bash
echo "!/path/to/file" >> .gitignore
git dotfiles add /path/to/file
git dotfiles commit -m "feat: Add file"
```

Remove a file from the dotfile repo by removing it from the gitignore file
