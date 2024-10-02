#!/bin/zsh

#https://github.com/neovim/neovim/blob/master/INSTALL.md 

cd
curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-arm64.tar.gz
tar xzf nvim-macos-arm64.tar.gz
./nvim-macos-arm64/bin/nvim
