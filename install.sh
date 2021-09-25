#!/bin/bash

# Color
# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

PYTHON_VERSION="3.9.7"
DEBUGPY_PATH="$HOME/.local/debugpy"

function red {
    printf "%s%s%s\n" "$RED" "$@" "$NC"
}

function green {
    printf "%s%s%s\n" "$GREEN" "$@" "$NC"
}

function yellow {
    printf "%s%s%s\n" "$YELLOW" "$@" "$NC"
}

font() {
  echo -e "$(yellow "Installing font: JetBrains Nerd Font")"
  if [[ -e "$HOME/.fonts/" ]]; then
    echo -e "$(yellow "Fonts directory found")"
  else
    echo -e "$(yellow "Creating fonts directory")"
    mkdir "$HOME/.fonts/"
  fi
  (
  cd "$HOME/.fonts/" || exit
  wget2 --progress bar https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip
  unzip ./JetBrainsMono.zip
  fc-cache -f -v
  )
  echo -e "$(green "Finished installing font")"
}

distro_packages() {
  echo -e "$(yellow "Updating Package Repository")"
  sudo apt update
  echo -e "$(yellow "Attempting to upgrade packages")"
  sudo apt upgrade
  echo -e "$(yellow "Installing Python build dependencies")"
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
                  liblzma-dev \
                  ninja-build
  echo -e "$(yellow "\nInstalling other packages\n")"
  sudo apt install \
                  stow \
                  ripgrep \
                  bat \
  echo -e "$(green "\nFinished installing packages\n")"
}

install_exa() {
  echo -e "$(yellow "Installing exa")"
  wget2 --progress bar https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip
  unzip exa-linux-x86_64-v0.10.1.zip -d exa
  sudo cp ./exa/bin/exa /usr/local/bin 
  sudo cp ./exa/man/exa.1 /usr/share/man/man1
  sudo cp ./exa/completions/exa.bash /etc/bash_completion.d/
  rm -r exa
  rm exa-linux-x86_64-v0.10.1.zip
  echo -e "$(green "Finished installing exa")"
}

install_starship() {
  echo -e "$(yellow "Installing Starship")"
  sh -c "$(curl -fsSL https://starship.rs/install.sh)"
  echo -e "$(green "Finished installing Starship")"
}

pyenv() {
  echo -e "$(yellow "Installing pyenv")"
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  ( cd ~/.pyenv && src/configure && make -C src )
  echo -e "$(green "Finished installing pyenv")"
  echo -e "\n\n"
  echo -e "$(yellow "Installing latest stable Python interpreter")"
  pyenv install $PYTHON_VERSION || echo -e "$(red Failed installing latest Python interpreter)"
  echo -e "$(green Finished installing Python)"
}

debugpy() {
  echo -e "$(yellow "Installing debugpy")"  # separate venv
  python -m venv DEBUGPY_PATH
  "$DEBUGPY_PATH/bin/python" -m pip install debugpy
  echo -e "$(green "Finished installing debugpy")"
}

pipx() {
  echo -e "$(yellow "Installing Pipx")"
  python -m pip install --user pipx
  python -m pipx ensurepath
  echo -e "$(green "Finished installing Pipx")"
}

poetry() {
  echo -e "$(yellow "Installing poetry")"
  curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
  echo -e "$(green "Finished installing poetry")"
}

pipx_programs() {
  prgs=('black' 'isort' 'flake8' 'cookiecutter')

  for i in "${prgs[@]}"; do
    if pipx install "$i"; then
      echo -e "$(green "Installed $i")"
    else
      echo -e "$(red "Error installing $i")"
      echo Exiting; exit
    fi
  done

}

python() {
  echo "Beginning Python setup"
  pyenv
  pip
  poetry
  pipx
  pipx_programs
  debugpy
  echo "Python setup complete"
}

nvm() {
  echo -e "$(yellow "Installing nvm")"
  if wget --progress bar -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash; then
    echo -e "$(green "Successfully installed nvm")"
  else
    echo -e "$(red "Error installing nvm. Exiting...")"; exit 1
  fi
}

npm() {
  echo -e "$(yellow "Installing npm packages")"
  if npm install -g pyright \
    vscode-langservers-extracted \
    yaml-language-server \
    prettier \
    bash-language-server; then
    npm config set ignore-scripts true
    echo -e "$(green "Finished npm packages")"
  else
    echo -e "$(red "Failed to install npm packages")"; exit 1
  fi
}

node() {
  echo -e "$(yellow "Beginning node setup")"
  nvm
  nvm install node --latest-npm
  npm
  echo -e "$(green "Finished node setup")"
}

lua_lang_server() {
  echo "Installing lua lang server"
  git clone https://github.com/sumneko/lua-language-server
  (
  cd lua-language-server || exit
  git submodule update --init --recursive
    (
    cd 3rd/luamake || exit
    ./compile/install.sh
    )
  ./3rd/luamake/luamake rebuild
  )
  echo "Finished installing lua lang server"
}

go_programs() {
  echo "Installing Go programs"
  go get efm-lang-server
  go get lazygit
  echo "Finished installing Go programs"
}

go() {
  echo -e "$(yellow "Installing Golang")"
  wget2 --progress bar https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
  rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
  echo -e "$(green "Finished installing Golang")"
  go_programs
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

# TODO: Exit upon a component failure (requires above todo for re-running)

# install_distro_packages
