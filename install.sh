#!/bin/bash

font() {
  echo "Installing font: JetBrains Nerd Font"
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

pipx_programs() {
  echo "Installing black"
  echo "Installing isort"
  echo "Installing flake8"
  echo "Installing cookiecutter"
}

python() {
  echo "Beginning Python setup"
  pyenv()
  pip()
  pipx_programs()
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
  nvm()
  npm()
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

  echo "Finished configuration"
}


# *---------*
# |Execution|
# *---------*

# install_distro_packages
