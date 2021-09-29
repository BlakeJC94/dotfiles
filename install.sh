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

function get_download_url {
  #https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8#gistcomment-2758561
  wget -nv -O- https://api.github.com/repos/"$1"/"$2"/releases/latest 2>/dev/null |  jq -r ".assets[] | select(.browser_download_url | contains(\"$3\")) | .browser_download_url"
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
  URL=$(get_download_url "ryanoasis" "nerd-fonts" "JetBrainsMono.zip")
	BASE=$(basename "$URL")
	wget -q -nv -O "$BASE" "$URL"
  unzip "$BASE"
  fc-cache -f -v
  )
  echo -e "$(green "Finished installing font\n")"
}

distro_packages() {
  echo -e "$(yellow "\nUpdating Package Repository\n")"
  sudo apt update
  echo -e "$(yellow "\nAttempting to upgrade packages\n")"
  sudo apt upgrade -y
  echo -e "$(yellow "\nInstalling Python build dependencies\n")"
  sudo apt install -y \
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
                  ninja-build \
                  jq \
                  unzip
  echo -e "$(yellow "Installing Neovim build dependencies")"
  sudo apt-get install -y gettext libtool libtool-bin autoconf automake cmake g++ pkg-config curl

  echo -e "$(yellow "\nInstalling other packages\n")"
  sudo apt install -y \
                  stow \
                  bat
  echo -e "$(green "\nFinished installing packages\n")"
}

efm-langserver() {
  URL=$(get_download_url "mattn" "efm-langserver" "linux_amd64")
	BASE=$(basename "$URL")
	wget -q -nv -O "$BASE" "$URL"
  tar -xf "$BASE"
  (
  cd "${BASE%.tar.gz}" || exit
  mv "efm-langserver" ~/.local/bin/
  )
  rm -r "${BASE%.tar.gz}"
  rm "$BASE"
}

lazygit() {
  URL=$(get_download_url "jesseduffield" "lazygit" "Linux_x86_64")
	BASE=$(basename "$URL")
	wget -q -nv -O "$BASE" "$URL"
  tar -C ~/.local/bin/ -xf "$BASE"
  rm -r "$BASE"
  # these files are included in the archive and are not needed
  rm ~/.local/bin/LICENSE
  rm ~/.local/bin/README.md
}

exa() {
  echo -e "$(yellow "Installing exa")"
  # we need the '-v' at the end to prevent it from matching with "linux-x86_64-musl"
  URL=$(get_download_url "ogham" "exa" "linux-x86_64-v")
	BASE=$(basename "$URL")
	wget -q -nv -O "$BASE" "$URL"
  unzip "$BASE" -d exa
  sudo cp ./exa/bin/exa /usr/local/bin 
  sudo cp ./exa/man/exa.1 /usr/share/man/man1
  sudo cp ./exa/completions/exa.bash /etc/bash_completion.d/
  rm -r exa
  rm "$BASE"
  echo -e "$(green "Finished installing exa\n")"
}

starship() {
  echo -e "$(yellow "Installing Starship")"
  sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
  echo -e "$(green "Finished installing Starship\n")"
}

install_pyenv() {
  echo -e "$(yellow "Installing pyenv")"
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  ( cd ~/.pyenv && src/configure && make -C src )
  echo -e "$(green "Finished installing pyenv\n")"
  echo -e "\n\n"
  echo -e "$(yellow "Installing latest stable Python interpreter")"
  . ~/.profile 
  pyenv install $PYTHON_VERSION || echo -e "$(red "Failed installing latest Python interpreter")"
  echo -e "$(green "Finished installing Python\n")"
}

install_pip() {
  echo -e "$(yellow "\nInstalling pip\n")"
  if python -m ensurepip --upgrade; then
    echo -e "$(green "Finished installing pip\n")"
  else
    echo -e "$(red "Error installing pip\n")"
  fi
}

debugpy() {
  echo -e "$(yellow "Installing debugpy")"  # separate venv
  python -m venv DEBUGPY_PATH
  "$DEBUGPY_PATH/bin/python" -m pip install debugpy
  echo -e "$(green "Finished installing debugpy\n")"
}

install_pipx() {
  echo -e "$(yellow "Installing Pipx")"
  python -m pip install --user pipx
  python -m pipx ensurepath
  echo -e "$(green "Finished installing Pipx\n")"
}

poetry() {
  echo -e "$(yellow "Installing poetry")"
  curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
  echo -e "$(green "Finished installing poetry\n")"
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

install_python() {
  echo -e "$(yellow "Beginning Python setup")"
  install_pyenv
  install_pip
  poetry
  install_pipx
  pipx_programs
  debugpy
  echo -e "$("Python setup complete\n")"
}

install_nvm() {
  echo -e "$(yellow "Installing nvm")"
  if wget --progress bar -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash; then
    echo -e "$(green "Successfully installed nvm")"
  else
    echo -e "$(red "Error installing nvm. Exiting...")"; exit 1
  fi
}

npm_pkgs() {
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

install_node() {
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

# go_programs() {
#   echo -e "$(yellow "Installing Go programs")"
#   go get efm-lang-server
#   go get lazygit
#   echo -e "$(green "Finished installing Go programs")"
# }
# 
# go() {
#   echo -e "$(yellow "Installing Golang")"
#   wget2 --progress bar https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
#   rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz
#   echo -e "$(green "Finished installing Golang")"
#   go_programs
# }

build_neovim() {
  sudo rm /usr/local/bin/nvim
  sudo rm -r /usr/local/share/nvim/
  echo -e "$(yellow "Building Neovim")"
  URL=$(wget -nv -O- https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null |  jq -r "select(.tarball_url) | .tarball_url")
  BASE=$(basename "$URL").tar.gz
  wget -q -nv -O "$BASE" "$URL"
  mkdir ./neovim-src  # the dir name after extraction can be unpreditable, so we extract to a predictable location
  tar xf "$BASE" -C ./neovim-src/ --strip-components 1
  (
  cd ./neovim-src/ || exit
  sudo make CMAKE_BUILD_TYPE=Release install
  )
  sudo rm "$BASE"
  sudo rm -r ./neovim-src/
  echo -e "$(green "Finished building Neovim")"
}

deploy_config() {
  echo -e "$(yellow "Deploying dotfiles")"
  rm .bashrc
  rm .profile
  (
  cd dotfiles/ || exit 1
  # some files (i.e. install.sh, LICENSE.md, etc) cause stow to throw an error
  # we provide specific packages to stow so it will ignore those files
  stow nvim pypoetry starship zathura lazygit kitty git cookiecutter conky bash
  )
  echo -e "$(green "Finished deploying dotfiles")"
}


# *---------*
# |Execution|
# *---------*

# TODO: Handle cases where some software or component is already installed
# ... prompt to update when necessary

# TODO: Exit upon a component failure (requires above todo for re-running)

# TODO: Progress bar: https://github.com/pollev/bash_progress_bar

# TODO: Don't display stdout; Show stderr if exit code is 1

# TODO: Take optional --update argument to update third-party programs

distro_packages
deploy_config
font
efm-langserver
lazygit
exa
starship
install_python
install_nvmnvm
install_nodenode
npm_pkgs
lua_lang_server
build_neovim

