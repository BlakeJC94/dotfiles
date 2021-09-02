#!/usr/bin/env bash

# cd ~
sudo rm -r neovim-0.5.0
# e --branch master --depth 1 https://github.com/neovim/neovim
wget https://github.com/neovim/neovim/archive/refs/tags/v0.5.0.tar.gz
tar xf v0.5.0.tar.gz
cd neovim-0.5.0
sudo make CMAKE_BUILD_TYPE=Release install
cd ..
sudo rm -r neovim-0.5.0
sudo rm v0.5.0.tar.gz 
# sudo rm -r /usr/local/share/nvim/runtime/plugin/
