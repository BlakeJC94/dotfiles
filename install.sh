#!/bin/bash

# Color
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function red {
    printf "${RED}$@${NC}\n"
}

function green {
    printf "${GREEN}$@${NC}\n"
}

function yellow {
    printf "${YELLOW}$@${NC}\n"
}

font() {
  echo $(yellow "Installing font: JetBrains Nerd Font")
  if [[ -e "$HOME/.fonts/" ]]; then
    echo $(yellow "Fonts directory found")
  else
    echo $(yellow "Creating fonts directory")
    mkdir $HOME/.fonts/
  fi
  cd $HOME/.fonts/
  wget2 --progress bar https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip
  unzip ./JetBrainsMono.zip
  fc-cache -f -v
  cd -
  echo $(green "Finished installing font")
}

distro_packages() {
  echo $(yellow "Updating Package Repository")
  sudo apt update
  echo $(yellow "Attempting to upgrade packages")
  sudo apt upgrade
  echo $(yellow "Installing Python build dependencies")
  sudo apt install \
                  make \
                  build-essential \
                  libssl-dev \
                  zlib1g-dev \
                  libbz2-dev \
                  libreadline-dev \
                  libsqlite3-dev \
                  curl \
                  wget2 \
                  llvm \
                  libncursesw5-dev \
                  xz-utils \
                  tk-dev \
                  libxml2-dev \
                  libxmlsec1-dev \
                  libffi-dev \
                  liblzma-dev
  echo $(yellow "Installing other packages")
  sudo apt install \
                  stow \
                  ripgrep \
                  bat \
                  dust
  echo $(green "Finished installing packages")
}

install_exa() {
  echo $(yellow "Installing exa")
  wget2 --progress bar https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip
  unzip exa-linux-x86_64-v0.10.1.zip -d exa
  sudo cp ./exa/bin/exa /usr/local/bin 
  sudo cp ./exa/man/exa.1 /usr/share/man/man1
  sudo cp ./exa/completions/exa.bash /etc/bash_completion.d/
  rm -r exa
  rm exa-linux-x86_64-v0.10.1.zip
  echo $(green "Finished installing exa")
}

install_starship() {
  echo $(yellow "Installing Starship")
  sh -c "$(curl -fsSL https://starship.rs/install.sh)"
  echo $(green "Finished installing Starship")
}

pyenv() {
  echo "Installing pyenv"

  echo "Installing latest stable Python interpreter"
}

pip() {
  echo "Installing Pip"

  echo "Installing debugpy"  # separate venv

  echo "Installing Pipx"
}

poetry() {
  echo "Installing poetry"

  echo "Finished installing poetry"
}

pipx_programs() {
  echo "Installing black"
  echo "Installing isort"
  echo "Installing flake8"
  echo "Installing cookiecutter"
  echo "Installing ranger"
}

python() {
  echo "Beginning Python setup"
  pyenv
  pip
  pipx_programs
  poetry
  echo "Python setup complete"
}

nvm() {
  echo "Installing nvm"

  echo "Finished nvm install"
}

npm() {
  echo "Installing npm packages"
  # pyright
  # vscode-langservers-extracted
  # yaml-language-server
  # prettier
  echo "Finished npm packages"
}
node() {
  echo "Beginning node setup"
  nvm
  npm
  echo "Finished node setup"
}

lua_lang_server() {
  echo "Installing lua lang server"

  echo "Finished installing lua lang server"
}

go_programs() {
  echo "Installing Go programs"
  go get efm-lang-server
  go get lazygit
  echo "Finished installing Go programs"
}

go() {
  echo "Installing Golang"

  echo "Finished installing Golang"
}

build_neovim() {
  echo "Building Neovim"

  echo "Finished building Neovim"
}

stow() {
  echo "Creating symlinks"
  stow
}


# *---------*
# |Execution|
# *---------*

# TODO: Handle cases where some software or component is already installed
# ... prompt to update when necessary

# install_distro_packages
