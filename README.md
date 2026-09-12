# Dotfiles

Dotfiles for my various systems, feel free to browse for inspiration (Clone and
use them at your own risk though)

Current stack:

* **Terminal**: Ghostty
* **Shell**: `bash` (Linux) / `zsh` (MacOS)
* **Editor**: `nvim`
* **Package manager**: Homebrew
* **Web Browser**: Firefox
* **LLM Client**: `llm-cli`
* **Coding agent**: `pi`
* **Project env manager**: `mise`
* **Python env manager**: `uv`
* **Colorscheme**: Gruvbox Dark / Gruvbox Light
* **Grammar checker**: `write-good`

## Setup

Run the install script:

```sh
curl -fsSL 'https://gitlab.com/blakejc/dotfiles/-/raw/main/.install?ref_type=heads' | bash
```

The tools are activated by the created `.dotfiles.activate` file in `$HOME`.
Source the shell RC to get all the settings and whatnot (or start a new shell)

```bash
source .bashrc  # If on bash
source .zshrc   # If on zsh
```

## Usage

### Adding files

Add a file to the dotfile repo:

```bash
dtf add /path/to/file  # Will warn when you try to add a dir
dtf cm "feat: Add file"
dtf push

# Shortcut for adding all tracked files in a "sync commit"
dtf sync
dtf push

# Shorter shortcut for sync + push
dtf yeet

# Get latest
dtf pull
```
