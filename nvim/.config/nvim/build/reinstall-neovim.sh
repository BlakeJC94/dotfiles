#!bin/bash

echo "Uninstalling Neovim"
sudo rm /usr/local/bin/nvim
sudo rm -r /usr/local/share/nvim/

./install-neovim.sh
