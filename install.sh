#!/bin/bash

# Progress bar
# progreSh 10
progreSh() {
    LR='\033[1;31m'
    LG='\033[1;32m'
    LY='\033[1;33m'
    LC='\033[1;36m'
    LW='\033[1;37m'
    NC='\033[0m'
    if [ "${1}" = "0" ]; then TME=$(date +"%s"); fi
    SEC=`printf "%04d\n" $(($(date +"%s")-${TME}))`; SEC="$SEC sec"
    PRC=`printf "%.0f" ${1}`
    SHW=`printf "%3d\n" ${PRC}`
    LNE=`printf "%.0f" $((${PRC}/2))`
    LRR=`printf "%.0f" $((${PRC}/2-12))`; if [ ${LRR} -le 0 ]; then LRR=0; fi;
    LYY=`printf "%.0f" $((${PRC}/2-24))`; if [ ${LYY} -le 0 ]; then LYY=0; fi;
    LCC=`printf "%.0f" $((${PRC}/2-36))`; if [ ${LCC} -le 0 ]; then LCC=0; fi;
    LGG=`printf "%.0f" $((${PRC}/2-48))`; if [ ${LGG} -le 0 ]; then LGG=0; fi;
    LRR_=""
    LYY_=""
    LCC_=""
    LGG_=""
    for ((i=1;i<=13;i++))
    do
    	DOTS=""; for ((ii=${i};ii<13;ii++)); do DOTS="${DOTS}."; done
    	if [ ${i} -le ${LNE} ]; then LRR_="${LRR_}#"; else LRR_="${LRR_}."; fi
    	echo -ne "  ${LW}${SEC}  ${LR}${LRR_}${DOTS}${LY}............${LC}............${LG}............ ${SHW}%${NC}\r"
    	if [ ${LNE} -ge 1 ]; then sleep .05; fi
    done
    for ((i=14;i<=25;i++))
    do
    	DOTS=""; for ((ii=${i};ii<25;ii++)); do DOTS="${DOTS}."; done
    	if [ ${i} -le ${LNE} ]; then LYY_="${LYY_}#"; else LYY_="${LYY_}."; fi
    	echo -ne "  ${LW}${SEC}  ${LR}${LRR_}${LY}${LYY_}${DOTS}${LC}............${LG}............ ${SHW}%${NC}\r"
    	if [ ${LNE} -ge 14 ]; then sleep .05; fi
    done
    for ((i=26;i<=37;i++))
    do
    	DOTS=""; for ((ii=${i};ii<37;ii++)); do DOTS="${DOTS}."; done
    	if [ ${i} -le ${LNE} ]; then LCC_="${LCC_}#"; else LCC_="${LCC_}."; fi
    	echo -ne "  ${LW}${SEC}  ${LR}${LRR_}${LY}${LYY_}${LC}${LCC_}${DOTS}${LG}............ ${SHW}%${NC}\r"
    	if [ ${LNE} -ge 26 ]; then sleep .05; fi
    done
    for ((i=38;i<=49;i++))
    do
    	DOTS=""; for ((ii=${i};ii<49;ii++)); do DOTS="${DOTS}."; done
    	if [ ${i} -le ${LNE} ]; then LGG_="${LGG_}#"; else LGG_="${LGG_}."; fi
    	echo -ne "  ${LW}${SEC}  ${LR}${LRR_}${LY}${LYY_}${LC}${LCC_}${LG}${LGG_}${DOTS} ${SHW}%${NC}\r"
    	if [ ${LNE} -ge 38 ]; then sleep .05; fi
    done
}

font() {
  echo "Installing font: JetBrains Nerd Font"
  if [[ -e "$HOME/.fonts/"]]; then
    echo "Fonts directory found"
  else
    echo "Creating fonts directory"
    mkdir $HOME/.fonts/
  fi
  cd $HOME/.fonts/
  wget2 --progress bar https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/JetBrainsMono.zip
  unzip ./JetBrainsMono.zip
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
  pyenv()
  pip()
  pipx_programs()
  poetry()
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
  stow

  echo "Finished configuration"
}


# *---------*
# |Execution|
# *---------*

# install_distro_packages
