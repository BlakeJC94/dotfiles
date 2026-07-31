# Dotfiles

Dotfiles for my various systems, feel free to browse for inspiration (Clone and
use them at your own risk though)

## Setup

Run the install script:

```sh
curl -fsSL https://gitlab.com/blakejc/dotfiles/-/raw/main/.install?ref_type=heads | sh
```
The tools are activated by the created `.dotfiles.activate` file in `$HOME`.
Source the shell RC to get all the settings and whatnot (or start a new shell)

```bash
source .bashrc  # If on bash
source .zshrc   # If on zsh
```

On Linux, must be manually run:

```bash
just apt-up
```

## Usage

### Adding files

Add a file to the dotfile repo:

```bash
dtf add /path/to/file
dtf commit -m "feat: Add file"
dtf push

# Get latest
dtf push
```
