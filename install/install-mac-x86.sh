#!/bin/zsh

#https://github.com/neovim/neovim/blob/master/INSTALL.md 

cd
curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-x86_64.tar.gz
tar xzf nvim-macos-x86_64.tar.gz
./nvim-macos-x86_64/bin/nvim