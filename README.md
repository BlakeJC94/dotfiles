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

If there are conflicts, destroy current state with
`git dotfiles checkout --force`. Otherwise, here's a non-destructive command to
use:

```bash
mkdir -p .config-backup
git dotfiles checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | while read -r file; do
  mkdir -p ".config-backup/$(dirname "$file")"
  mv "$file" ".config-backup/$file"
done
git dotfiles checkout
```

Activate the auto tool installation scripts by creating a `.dotfiles-activate`
file in `$HOME`:

```bash
touch ~/.dotfiles-activate
```

Source the shell RC to get all the settings and whatnot (or start a new shell)

```bash
source .bashrc  # If on bash
source .zshrc   # If on zsh
```

A prompt will ask to install Brew on your system. This will also install
`mise`, `just`, and `pre-commit`, and will install the necessary git hooks.

After Brew is installed, it'll ask to install the set of tools. If you'd like
to do this later:

```bash
just brew-up
just cask-up  # MacOS only
just mise-up
```

On Linux, these must be manually run:

```bash
just soar-up
just apt-up
```

## Usage

### Adding files

Add a file to the dotfile repo:

```bash
echo "!/path/to/file" >> .gitignore
git dotfiles add /path/to/file
git dotfiles commit -m "feat: Add file"
```

Remember that the directory must be exempted from the ignore as well. For
example:

```
!.config/path/to
!.config/path/to/file.ext
```

Remove a file from the dotfile repo by removing the entries from the
`.gitignore` file

### Updates

Get the latest changes:

```bash
just pull
```

Push your latest changes

```bash
git dotfiles add ...
git dotfiles commit -m "..."
git dotfiles push


# Or, if you're lazy:
just sync
```
