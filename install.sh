#!/bin/bash

font() {
  echo "Installing font: JetBrains Nerd Font"
  if [[ -e "$HOME/.fonts/" ]]; then
    echo "Fonts directory found"
  else
    echo "Creating fonts directory"
    mkdir $HOME/.fonts/
  fi
  cd $HOME/.fonts/
  wget2 --progress bar https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip
  unzip ./JetBrainsMono.zip
  fc-cache -f -v
  cd -
}

distro_packages() {
  echo "Updating Package Repository"
  sudo apt update
  echo "Installing Packages"
  sudo apt install -f packages.txt
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

configs() {
  echo "Setting up configs"
  stow

  echo "Finished configuration"
}


# *---------*
# |Execution|
# *---------*

# install_distro_packages
